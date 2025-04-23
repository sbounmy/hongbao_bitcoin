# frozen_string_literal: true

require "rails_helper"

# Refactored Spec using Fixtures and Minimal Mocking
RSpec.describe Oauth::CallbackService do
  let(:google_client_id) { "google_client_id_123" }
  let(:google_client_secret) { "google_client_secret_456" }
  let(:code) { "valid_auth_code" }
  let(:callback_url) { "http://test.host/oauth/callback" }
  let(:service) { described_class.new }

  # --- Mocks for OAuth2 external calls ONLY ---
  let(:mock_token_client) { instance_double(OAuth2::Client) }
  let(:mock_auth_code_strategy) { instance_double(OAuth2::Strategy::AuthCode) }
  let(:mock_access_token) { instance_double(OAuth2::AccessToken) }
  # User info response body will be defined per context

  before do
    # Stub credentials (remains the same)
    allow(Rails.application.credentials).to receive(:dig).with(:google, :client_id).and_return(google_client_id)
    allow(Rails.application.credentials).to receive(:dig).with(:google, :client_secret).and_return(google_client_secret)

    # Stub OAuth2 client instantiation & auth_code strategy (remains the same)
    allow(OAuth2::Client).to receive(:new)
      .with(google_client_id, google_client_secret, site: "https://oauth2.googleapis.com", token_url: "/token")
      .and_return(mock_token_client)
    allow(mock_token_client).to receive(:auth_code).and_return(mock_auth_code_strategy)

    # Stub URL helper (remains the same)
    allow(service).to receive(:callback_oauth_url).and_return(callback_url)

    # NOTE: Default mocks for get_token and get are REMOVED from here.
    # They will be set specifically within each context below.
  end

  # Helper to call the service (remains the same)
  def call_service_directly(auth_code = code)
    service.call(auth_code)
  end

  describe "#call" do
    context "when token exchange fails" do
      let(:oauth_error) { OAuth2::Error.new(OAuth2::Response.new(Faraday::Response.new(status: 400, body: '{\"error\":\"invalid_grant\"}'))) } # More realistic error

      before do
        # Mock ONLY the token exchange failure
        allow(mock_auth_code_strategy).to receive(:get_token)
          .with(code, redirect_uri: callback_url)
          .and_raise(oauth_error)
      end

      it "raises the OAuth2::Error" do
        # This expectation remains, testing the service correctly bubbles up OAuth errors
        expect { call_service_directly }.to raise_error(oauth_error)
      end
    end

    # Context for User Info API call failures
    context "when fetching user info fails (API Error)" do
      let(:oauth_error) { OAuth2::Error.new(OAuth2::Response.new(Faraday::Response.new(status: 500, body: '{\"error\":\"server_error\"}'))) } # Realistic userinfo error

      before do
        # Mock successful token exchange...
        allow(mock_auth_code_strategy).to receive(:get_token)
          .with(code, redirect_uri: callback_url)
          .and_return(mock_access_token)
        # ...but mock failed user info fetch
        allow(mock_access_token).to receive(:get)
          .with("https://openidconnect.googleapis.com/v1/userinfo")
          .and_raise(oauth_error) # Assume .get raises on non-200
      end

      it "raises an error (likely OAuth2::Error)" do
        # Service should bubble this up, likely caught by ApplicationService wrapper later
        expect { call_service_directly }.to raise_error(oauth_error)
      end
    end

    context "when fetching user info fails (Invalid Response / Missing Data)" do
       # Simulate API returning success but missing required email
       let(:user_info_response_body) { { "sub" => "google_user_id_123", "name" => "Test User" }.to_json } # No email
       let(:mock_user_info_response) { instance_double(OAuth2::Response, status: 200, parsed: JSON.parse(user_info_response_body), body: user_info_response_body) }

       before do
         # Mock successful token exchange...
         allow(mock_auth_code_strategy).to receive(:get_token)
           .with(code, redirect_uri: callback_url)
           .and_return(mock_access_token)
         # ...mock successful user info fetch with incomplete data
         allow(mock_access_token).to receive(:get)
           .with("https://openidconnect.googleapis.com/v1/userinfo")
           .and_return(mock_user_info_response)
       end

       it "raises CallbackError for fetch failure (due to invalid data)" do
         # Service should validate the response data internally before attempting save
         expect { call_service_directly }.to raise_error(Oauth::CallbackService::CallbackError, /Fetching user info failed/)
       end
    end

    context "when user does not exist (New Sign Up)" do
      let(:new_user_email) { "new_signup@example.com" }
      let(:new_google_uid) { "new-google-uid-111" }
      let(:user_info_response_body) do
        { "sub" => new_google_uid, "email" => new_user_email, "email_verified" => true, "name" => "New User" }.to_json
      end
      let(:mock_user_info_response) { instance_double(OAuth2::Response, status: 200, parsed: JSON.parse(user_info_response_body), body: user_info_response_body) }

      before do
         # Mock successful token exchange & user info fetch
         allow(mock_auth_code_strategy).to receive(:get_token).and_return(mock_access_token)
         allow(mock_access_token).to receive(:get).and_return(mock_user_info_response)
      end

      it "creates a new User" do
        # Check actual database change
        expect { call_service_directly }.to change(User, :count).by(1)
        expect(User.find_by(email: new_user_email)).not_to be_nil
      end

      it "creates a new Identity" do
        # Check actual database change
        expect { call_service_directly }.to change(Identity, :count).by(1)
        expect(Identity.find_by(provider_name: "Google", provider_uid: new_google_uid)).not_to be_nil
      end

      it "links the Identity to the new User" do
        call_service_directly
        user = User.find_by!(email: new_user_email)
        identity = Identity.find_by!(provider_name: "Google", provider_uid: new_google_uid)
        expect(identity.user).to eq(user)
      end

      it "returns a successful response" do
        result = call_service_directly
        expect(result).to be_success
      end

      it "returns the new User in the payload" do
        result = call_service_directly
        user = User.find_by!(email: new_user_email)
        expect(result.payload).to eq(user)
      end

       # Scenario: User save fails due to validation (e.g., invalid data from API *despite* 200 OK)
       context "and user save fails (e.g., invalid email format from API)" do
         let(:invalid_user_email) { "invalid-email" }
         let(:user_info_response_body_invalid) do
           { "sub" => "new-google-uid-validation-fail", "email" => invalid_user_email }.to_json
         end
         let(:mock_user_info_response_invalid) { instance_double(OAuth2::Response, status: 200, parsed: JSON.parse(user_info_response_body_invalid), body: user_info_response_body_invalid) }

         before do
           allow(mock_auth_code_strategy).to receive(:get_token).and_return(mock_access_token)
           # Mock user info fetch returning data that will fail User model validation
           allow(mock_access_token).to receive(:get).and_return(mock_user_info_response_invalid)
         end

         it "raises ActiveRecord::RecordInvalid" do
           # Expect database validation error, no longer the service's CallbackError
           expect { call_service_directly }.to raise_error(ActiveRecord::RecordInvalid)
         end
       end

      # No need for separate identity save fail context if using real DB;
      # it would likely only fail for uniqueness constraints handled by find_or_create logic
    end

    context "when user exists, but identity does not (Linking Account)" do
      let(:existing_user_for_link) { users(:satoshi) } # From fixture
      let(:new_google_uid_for_link) { "link-account-google-uid-222" }
      let(:user_info_response_body) do
        { "sub" => new_google_uid_for_link, "email" => existing_user_for_link.email, "email_verified" => true }.to_json
      end
      let(:mock_user_info_response) { instance_double(OAuth2::Response, status: 200, parsed: JSON.parse(user_info_response_body), body: user_info_response_body) }

      before do
         # Mock successful token exchange & user info fetch
         allow(mock_auth_code_strategy).to receive(:get_token).and_return(mock_access_token)
         allow(mock_access_token).to receive(:get).and_return(mock_user_info_response)
      end

      it "does not create a new User" do
        # Check actual database state
        expect { call_service_directly }.not_to change(User, :count)
      end

      it "creates a new Identity" do
        # Check actual database change
        expect { call_service_directly }.to change(Identity, :count).by(1)
      end

      it "links the new Identity to the existing User" do
        call_service_directly
        identity = Identity.find_by!(provider_name: "Google", provider_uid: new_google_uid_for_link)
        expect(identity.user).to eq(existing_user_for_link)
      end

      it "returns a successful response" do
        expect(call_service_directly).to be_success
      end

      it "returns the existing User in the payload" do
        result = call_service_directly
        expect(result.payload).to eq(existing_user_for_link)
      end
    end

    context "when both user and identity exist (Regular Sign In)" do
       let(:signed_in_user) { users(:satoshi) } # Assumes a fixture user with identity
       let(:signed_in_identity) { identities(:google) } # Assumes a fixture identity linked to above user
       let(:user_info_response_body) do
         { "sub" => signed_in_identity.provider_uid, "email" => signed_in_user.email, "email_verified" => true }.to_json
       end
       let(:mock_user_info_response) { instance_double(OAuth2::Response, status: 200, parsed: JSON.parse(user_info_response_body), body: user_info_response_body) }

       before do
         # Mock successful token exchange & user info fetch
         allow(mock_auth_code_strategy).to receive(:get_token).and_return(mock_access_token)
         allow(mock_access_token).to receive(:get).and_return(mock_user_info_response)
       end

       it "does not create a new User" do
         expect { call_service_directly }.not_to change(User, :count)
       end

       it "does not create a new Identity" do
         expect { call_service_directly }.not_to change(Identity, :count)
       end

       it "returns a successful response" do
         expect(call_service_directly).to be_success
       end

       it "returns the existing User in the payload" do
         result = call_service_directly
         expect(result.payload).to eq(signed_in_user)
       end
    end
  end
end
