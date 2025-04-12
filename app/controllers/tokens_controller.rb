class TokensController < ApplicationController
  allow_unauthenticated_access only: [ :paid ]
  skip_before_action :verify_authenticity_token, only: [ :paid ]

  def create
  end

  def paid
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )

      case event.type
      when "checkout.session.completed"
        session = event.data.object
        # Handle the checkout session here
        # You can access session.customer, session.payment_status, etc.
      end

      render json: { message: :success }
    rescue JSON::ParserError => e
      render json: { error: { message: e.message } }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      render json: { error: { message: e.message } }, status: :bad_request
    end
  end

  private

  def endpoint_secret
    Rails.application.credentials.dig(:stripe, :signing_secret)
  end
end
