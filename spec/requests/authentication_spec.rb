# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "protected routes" do
    it "redirects unauthenticated users to signup" do
      get tokens_path
      expect(response).to redirect_to(signup_path)
    end

    context "when authenticated" do
      let(:user) { users(:satoshi) }

      before do
        post session_path, params: { email: user.email, password: "03/01/2009" }
      end

      it "allows access to protected routes" do
        get orders_path
        expect(response).to be_successful
      end
    end
  end
end
