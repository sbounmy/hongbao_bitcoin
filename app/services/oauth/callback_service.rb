# frozen_string_literal: true

require "oauth2"
require "securerandom"

module Oauth
  class CallbackService < ApplicationService
    # Custom error for callback specific issues
    class CallbackError < StandardError
      attr_reader :user_message

      # Allow storing a user-friendly message alongside the technical one
      def initialize(message, user_message: nil)
        super(message)
        @user_message = user_message || message # Default to technical message if no user message provided
      end
    end

    attr_reader :code

    def call(code)
      @code = code
      token = exchange_code_for_token
      user_info = fetch_user_info(token)
      identity = find_or_initialize_identity(user_info["sub"])
      user = find_or_create_user(identity, user_info["email"])

      save_identity_and_user(identity, user)

      success(user)
    end

    private

    def exchange_code_for_token
      client.auth_code.get_token(
        code,
        redirect_uri: callback_oauth_url # URL helper from ApplicationService
      )
    end

    def fetch_user_info(token)
      response = token.get("https://openidconnect.googleapis.com/v1/userinfo")

      user_info = response.parsed
      unless user_info && user_info["email"].present? && user_info["sub"].present?
        Rails.logger.error("OAuth Fetch User Info Error: Missing email or sub in response: #{user_info}")
        raise CallbackError.new(
          "Fetching user info failed: Invalid response",
          user_message: "Authentication failed: Necessary profile information (email, ID) was missing from Google."
        )
      end
      user_info
    end

    def find_or_initialize_identity(provider_uid)
      Identity.find_or_initialize_by(provider_name: "Google", provider_uid: provider_uid)
    end

    def find_or_create_user(identity, email)
      return identity.user if identity.persisted? && identity.user

      user = User.find_by(email:)

      if user.nil?
        # User doesn't exist, create a new one
        password = SecureRandom.hex(16)
        user = User.new(
          email:,
          password: password,
          password_confirmation: password
          # Add any other required user attributes here if needed
          # Consider adding email verification bypass or auto-verification for OAuth users.
        )
      end
      # If user exists or was just initialized, link the identity
      # The actual saving/validation happens in save_identity_and_user
      identity.user = user
      user # Return the user object (might not be persisted yet)
    end

    def save_identity_and_user(identity, user)
      # Use a transaction to ensure both user (if new) and identity are saved, or neither.
      ActiveRecord::Base.transaction do
        unless user.persisted? # Save the user only if they are new
          user.save!
        end
        identity.save!
      end
    end

    def client
      OAuth2::Client.new(
        credentials(:google, :client_id),
        credentials(:google, :client_secret),
        site: "https://oauth2.googleapis.com",
        token_url: "/token"
      )
    end
  end
end
