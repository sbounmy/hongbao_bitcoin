module Webhooks
  class BtcpayController < ApplicationController
    skip_before_action :verify_authenticity_token

    skip_before_action :require_authentication

    def create
      result = Checkout::Btcpay::Webhook.call(request)

      if result.success?
        head :ok
      else
        Rails.logger.error "BTCPay Webhook Failed: #{result.error}"
        head :bad_request
      end
    end
  end
end
