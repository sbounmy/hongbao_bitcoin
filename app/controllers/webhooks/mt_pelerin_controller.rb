module Webhooks
  class MtPelerinController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_signature

    def create
      hong_bao = HongBao.find_by!(public_key: params[:address])
      hong_bao.update!(paid: true)
      head :ok
    end

    private

    def verify_signature
      # Verify Mt Pelerin webhook signature
      signature = request.headers["Mtp-Signature"]
      computed = OpenSSL::HMAC.hexdigest("sha256", ENV["MT_PELERIN_SIGNATURE_KEY"], request.raw_post)
      head :unauthorized unless Rack::Utils.secure_compare(signature, computed)
    end
  end
end
