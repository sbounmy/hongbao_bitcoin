# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordsController, type: :controller do
  describe "POST #create" do
    let(:user) { users(:satoshi) }

    it "sends password reset email for existing user" do
      perform_enqueued_jobs do
        expect {
          post :create, params: { email: user.email }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to eq("Reset your password")
    end

    it "handles non-existent email differently" do
      post :create, params: { email: "nonexistent@example.com" }
      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to include("No account found")
    end
  end

  describe "GET #edit" do
    let(:user) { users(:satoshi) }
    let(:token) { user.password_reset_token }

    it "renders the edit template with valid token" do
      get :edit, params: { token: token }
      expect(response).to be_successful
      expect(response).to render_template(:edit)
      expect(assigns(:user)).to eq(user)
    end

    it "rejects invalid token" do
      get :edit, params: { token: "invalid" }
      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to include("invalid or has expired")
    end
  end

  describe "PUT #update" do
    let(:user) { users(:satoshi) }
    let(:token) { user.password_reset_token }
    let(:new_password) { "newpassword123" }

    it "updates password with valid parameters" do
      put :update, params: {
        token: token,
        password: new_password,
        password_confirmation: new_password
      }
      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq("Password has been reset.")
      expect(user.reload.authenticate(new_password)).to be_truthy
    end

    it "validates password confirmation" do
      put :update, params: {
        token: token,
        password: new_password,
        password_confirmation: "different"
      }
      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to eq("Passwords did not match.")
    end
  end
end
