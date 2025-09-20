require 'rails_helper'

RSpec.describe "SavedHongBaos", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }
  let(:valid_address) { "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh" }

  before do
    # Sign in the user
    post session_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /saved_hong_baos" do
    it "returns successful response" do
      get saved_hong_baos_path
      expect(response).to have_http_status(:success)
    end

    it "displays saved hong baos" do
      SavedHongBao.create!(user: user, name: "Friend", address: valid_address)

      get saved_hong_baos_path
      expect(response.body).to include("Friend")
      expect(response.body).to include(valid_address)
    end

    it "shows empty state when no saved hong baos" do
      get saved_hong_baos_path
      expect(response.body).to include("No saved Hong Baos yet")
    end
  end

  describe "GET /saved_hong_baos/new" do
    it "returns successful response" do
      get new_saved_hong_bao_path
      expect(response).to have_http_status(:success)
    end

    it "pre-fills address from params" do
      get new_saved_hong_bao_path, params: { address: valid_address }
      expect(response.body).to include(valid_address)
    end
  end

  describe "POST /saved_hong_baos" do
    context "with valid params" do
      let(:valid_params) do
        {
          saved_hong_bao: {
            name: "Test Friend",
            address: valid_address,
            notes: "Birthday gift"
          }
        }
      end

      it "creates a new saved hong bao" do
        expect {
          post saved_hong_baos_path, params: valid_params
        }.to change(SavedHongBao, :count).by(1)
      end

      it "redirects to index with success message" do
        post saved_hong_baos_path, params: valid_params
        expect(response).to redirect_to(saved_hong_baos_path)
        follow_redirect!
        expect(response.body).to include("Hong Bao saved successfully!")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          saved_hong_bao: {
            name: "",
            address: "invalid",
            notes: ""
          }
        }
      end

      it "does not create a new saved hong bao" do
        expect {
          post saved_hong_baos_path, params: invalid_params
        }.not_to change(SavedHongBao, :count)
      end

      it "renders new template with errors" do
        post saved_hong_baos_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Please fix the following errors")
      end
    end
  end

  describe "GET /saved_hong_baos/:id" do
    let(:saved_hong_bao) do
      SavedHongBao.create!(user: user, name: "Friend", address: valid_address)
    end

    it "returns successful response" do
      get saved_hong_bao_path(saved_hong_bao)
      expect(response).to have_http_status(:success)
    end

    it "displays hong bao details" do
      get saved_hong_bao_path(saved_hong_bao)
      expect(response.body).to include("Friend")
      expect(response.body).to include(valid_address)
      expect(response.body).to include("Current Balance")
      expect(response.body).to include("Transaction History")
    end
  end

  describe "DELETE /saved_hong_baos/:id" do
    let!(:saved_hong_bao) do
      SavedHongBao.create!(user: user, name: "Friend", address: valid_address)
    end

    it "destroys the saved hong bao" do
      expect {
        delete saved_hong_bao_path(saved_hong_bao)
      }.to change(SavedHongBao, :count).by(-1)
    end

    it "redirects to index with success message" do
      delete saved_hong_bao_path(saved_hong_bao)
      expect(response).to redirect_to(saved_hong_baos_path)
      follow_redirect!
      expect(response.body).to include("Hong Bao removed from saved list")
    end
  end

  describe "POST /saved_hong_baos/scan" do
    context "with valid scanned key" do
      before do
        allow(HongBaos::Scanner).to receive(:call).and_return(
          OpenStruct.new(
            success?: true,
            payload: OpenStruct.new(address: valid_address)
          )
        )
      end

      it "renders new form with scanned address" do
        post scan_saved_hong_baos_path, params: { scanned_key: valid_address }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(valid_address)
      end
    end

    context "with invalid scanned key" do
      before do
        allow(HongBaos::Scanner).to receive(:call).and_return(
          OpenStruct.new(
            success?: false,
            error: OpenStruct.new(user_message: "Invalid QR code")
          )
        )
      end

      it "redirects with error message" do
        post scan_saved_hong_baos_path, params: { scanned_key: "invalid" }
        expect(response).to redirect_to(new_saved_hong_bao_path)
        follow_redirect!
        expect(response.body).to include("Invalid QR code")
      end
    end
  end

  describe "authorization" do
    it "prevents access to other users' saved hong baos" do
      other_user = User.create!(email: "other@example.com", password: "password123")
      other_hong_bao = SavedHongBao.create!(user: other_user, name: "Other", address: valid_address)

      expect {
        get saved_hong_bao_path(other_hong_bao)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
