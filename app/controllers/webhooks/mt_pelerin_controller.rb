module Webhooks
  class MtPelerinController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_auth_token
    before_action :verify_signature

    def create
      hong_bao = HongBao.find_by!(public_key: params[:address])

      # Verify the external_id matches our hong_bao id
      head :unauthorized unless params[:external_id] == hong_bao.id.to_s

      # Store the Mt Pelerin response
      hong_bao.update!(
        mt_pelerin_response: params.permit(:id, :amount, :currency, :address, :hash, :external_id)
      )

      hong_bao.pay!

      head :ok
    end

    private

    def verify_auth_token
      auth_token = request.headers["authentication_key"]
      expected_token = Rails.application.credentials.mt_pelerin.authentication_key

      unless auth_token.present? && Rack::Utils.secure_compare(auth_token, expected_token)
        head :unauthorized
      end
    end

    def verify_signature
      # Get the raw request body
      raw_body = request.raw_post

      # Compute signature using the signature key
      computed = OpenSSL::HMAC.hexdigest(
        "sha256",
        Rails.application.credentials.mt_pelerin.signature_key,
        raw_body
      )

      # Get signature from header
      signature = request.headers["Mtp-Signature"]

      # Compare signatures using secure comparison
      unless signature.present? && Rack::Utils.secure_compare(signature, computed)
        head :unauthorized
      end
    end
  end
end
