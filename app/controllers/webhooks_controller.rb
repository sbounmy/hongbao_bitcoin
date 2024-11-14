class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      status 400
      return
    end

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      hong_bao = HongBao.find_by(stripe_session_id: session.id)
      hong_bao&.paid!
    end

    render json: { status: "success" }
  end
end
