require "test_helper"

module Webhooks
  class MtPelerinControllerTest < ActionDispatch::IntegrationTest
    test "processes valid webhook" do
      hong_bao = hong_baos(:one)
      puts "Running valid webhook test"

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

      # Send webhook request
      post webhooks_mt_pelerin_url,
        params: payload,
        headers: {
          "Content-Type": "application/json",
          "authentication_key": Rails.application.credentials.mt_pelerin.authentication_key,
          "Mtp-Signature": signature
        },
        as: :json

      assert_response :success

      # Reload hong_bao and verify updates
      hong_bao.reload
      assert hong_bao.paid?
      assert_equal "479f628b0aace32cbdef99f5e4011c98", hong_bao.mt_pelerin_response_id
      assert_equal 990, hong_bao.mt_pelerin_response_amount
      assert_equal "USDC", hong_bao.mt_pelerin_response_currency
      assert_equal hong_bao.public_key, hong_bao.mt_pelerin_response_address
      assert_equal "0x4c50a6c6756d66ee87533ee7562b3e800a9e472e798d63f1d55228d81d84f773", hong_bao.mt_pelerin_response_hash
      assert_equal hong_bao.id.to_s, hong_bao.mt_pelerin_response_external_id
    end

    test "rejects invalid authentication key" do
      hong_bao = hong_baos(:one)

      payload = {
        id: "479f628b0aace32cbdef99f5e4011c98",
        external_id: hong_bao.id.to_s
      }

      signature = OpenSSL::HMAC.hexdigest(
        "sha256",
        Rails.application.credentials.mt_pelerin.signature_key,
        payload.to_json
      )

      post webhooks_mt_pelerin_url,
        params: payload,
        headers: {
          "Content-Type": "application/json",
          "authentication_key": "invalid_key",
          "Mtp-Signature": signature
        },
        as: :json

      assert_response :unauthorized
    end

    test "rejects invalid signature" do
      hong_bao = hong_baos(:one)

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

      post webhooks_mt_pelerin_url,
        params: payload,
        headers: {
          "Content-Type": "application/json",
          "authentication_key": Rails.application.credentials.mt_pelerin.auth_key,
          "Mtp-Signature": "wrong_#{signature}" # Intentionally wrong signature
        },
        as: :json

        assert_response :unauthorized
    end
  end
end
