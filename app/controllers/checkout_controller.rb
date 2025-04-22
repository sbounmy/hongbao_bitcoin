class CheckoutController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token, only: [ :webhook ]

  def create
    # Create a Stripe Checkout Session
    result = Checkout::Create.call(params, current_user:)
    if result.success?
      redirect_to result.payload.url, allow_other_host: true
    else
      flash[:alert] = "Payment failed. Please try again."
      redirect_to root_path
    end
  end

  def update
    result = Checkout::Update.call(current_user:)
    if result.success?
      redirect_to result.payload.url, allow_other_host: true
    else
      flash[:alert] = "Payment failed. Please try again."
      redirect_to tokens_path
    end
  end
  def success
    result = Checkout::Success.call(params[:session_id], authenticated: authenticated?)

    if result.success?
      flash[:notice] = "Payment successful! Your tokens have been credited."
      start_new_session_for(result.payload)
    else
      flash[:alert] = "Payment failed. Please try again."
    end
    redirect_to root_path
  end

  def webhook
    result = Checkout::Webhook.call(payload: request.body.read, sig_header: request.env["HTTP_STRIPE_SIGNATURE"])
    if result.success?
      render json: { message: :success }
    else
      render json: { error: { message: result.error.message } }, status: :bad_request
    end
  end


  def cancel
    # Handle cancelled payment
    flash[:alert] = "Payment cancelled."
    redirect_to root_path
  end
end
