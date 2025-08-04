# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  describe "POST #create" do
    let(:user) { users(:satoshi) }

    it "creates session for valid credentials" do
      expect {
        post :create, params: { email: user.email, password: "03/01/2009" }
      }.to change { Session.count }.by(1)

      expect(response).to be_successful
      expect(response.body).to include('turbo-stream action="redirect"')
    end

    it "rejects invalid credentials" do
      post :create, params: { email: user.email, password: "wrong" }
      expect(response).to redirect_to(signup_path(user: { email: user.email }))
      expect(flash[:alert]).to eq("Password is incorrect")
    end
  end

  describe "DELETE #destroy" do
    let(:user) { users(:satoshi) }

    before do
      session_record = Session.create!(user: user, user_agent: "Test", ip_address: "127.0.0.1")
      cookies.signed[:session_id] = session_record.id
    end

    it "destroys the session" do
      expect {
        delete :destroy
      }.to change { Session.count }.by(-1)

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Signed out successfully")
    end
  end
end
