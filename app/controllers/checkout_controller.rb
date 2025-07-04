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
    result = Checkout::Success.call(params[:session_id])

    if result.success?
      flash[:notice] = "Payment successful! Your tokens have been credited."
    else
      flash[:alert] = "Payment failed. Please try again."
    end
    redirect_to root_path
  end

  def webhook
    result = Checkout::Webhook.call(request)
    if result.success?
      render json: { message: :success }
    else
      Rails.logger.error("Stripe webhook error: #{result.error.message}")
      render json: { error: { message: result.error.message } }, status: :bad_request
    end
  end


  def cancel
    # Handle cancelled payment
    flash[:alert] = "Payment cancelled."
    redirect_to root_path
  end
end
