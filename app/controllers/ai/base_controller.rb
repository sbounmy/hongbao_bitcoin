module Ai
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [ :done ]
    allow_unauthenticated_access only: [ :done ]
    before_action :verify_webhook_token, only: [ :done ]

    def verify_webhook_token
      provided_token = request.headers["Authorization"]
      expected_token = "Bearer #{webhook_token}"

      if provided_token.nil? || !ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
        Rails.logger.error "Webhook authentication failed"
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    def webhook_token
      raise NotImplementedError, "Subclasses must implement the webhook_token method e.g. Rails.application.credentials.dig(:leonardo, :webhook_token)"
    end
  end
end
