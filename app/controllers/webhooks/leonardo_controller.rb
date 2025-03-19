require "open-uri"
require "net/http"

module Webhooks
  class LeonardoController < ApplicationController
    private

    def verify_webhook_token
      provided_token = request.headers["Authorization"]
      expected_token = "Bearer #{Rails.application.credentials.dig(:leonardo, :webhook_token)}"

      Rails.logger.info "Webhook auth - Provided token: #{provided_token}"
      Rails.logger.info "Webhook auth - Expected token: #{expected_token}"

      unless provided_token && ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
        Rails.logger.error "Webhook authentication failed"
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
