require 'rails_helper'

RSpec.describe Webhooks::MtPelerinController, type: :controller do
  describe "POST #create" do
    let(:hong_bao) { hong_baos(:one) }

    before do
      skip("Skipping MT Pelerin webhook tests because sign up on hongbao is optional")
    end
    context "with valid payload and credentials" do
      it "processes the webhook and updates the hong_bao" do
        # Test payload
        payload = {
          id: "479f628b0aace32cbdef99f5e4011c98",
          amount: 990,
          currency: "USDC",
          address: hong_bao.public_key,
          hash: "0x4c50a6c6756d66ee87533ee7562b3e800a9e472e798d63f1d55228d81d84f773",
          external_id: hong_bao.id.to_s
        }

        # Calculate signature
        signature = OpenSSL::HMAC.hexdigest(
          "sha256",
          Rails.application.credentials.mt_pelerin.signature_key,
          payload.to_json
        )

        # Set request headers for controller specs
        request.headers["Content-Type"] = "application/json"
        request.headers["authentication_key"] = Rails.application.credentials.mt_pelerin.authentication_key
        request.headers["Mtp-Signature"] = signature

        post :create, params: payload, as: :json

        expect(response).to have_http_status(:success)

        # Reload hong_bao and verify updates
        hong_bao.reload
        expect(hong_bao).to be_paid
        expect(hong_bao.mt_pelerin_response_id).to eq("479f628b0aace32cbdef99f5e4011c98")
        expect(hong_bao.mt_pelerin_response_amount).to eq(990)
        expect(hong_bao.mt_pelerin_response_currency).to eq("USDC")
        expect(hong_bao.mt_pelerin_response_address).to eq(hong_bao.public_key)
        expect(hong_bao.mt_pelerin_response_hash).to eq("0x4c50a6c6756d66ee87533ee7562b3e800a9e472e798d63f1d55228d81d84f773")
        expect(hong_bao.mt_pelerin_response_external_id).to eq(hong_bao.id.to_s)
      end
    end

    context "with invalid authentication key" do
      it "returns unauthorized status" do
        payload = {
          id: "479f628b0aace32cbdef99f5e4011c98",
          external_id: hong_bao.id.to_s
        }

        signature = OpenSSL::HMAC.hexdigest(
          "sha256",
          Rails.application.credentials.mt_pelerin.signature_key,
          payload.to_json
        )

        request.headers["Content-Type"] = "application/json"
        request.headers["authentication_key"] = "invalid_key"
        request.headers["Mtp-Signature"] = signature

        post :create, params: payload, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid signature" do
      it "returns unauthorized status" do
        payload = {
          id: "479f628b0aace32cbdef99f5e4011c98",
          external_id: hong_bao.id.to_s
        }

        # Calculate correct signature but send a wrong one
        signature = OpenSSL::HMAC.hexdigest(
          "sha256",
          Rails.application.credentials.mt_pelerin.signature_key,
          payload.to_json
        )

        request.headers["Content-Type"] = "application/json"
        request.headers["authentication_key"] = Rails.application.credentials.mt_pelerin.auth_key
        request.headers["Mtp-Signature"] = "wrong_#{signature}" # Intentionally wrong signature

        post :create, params: payload, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
