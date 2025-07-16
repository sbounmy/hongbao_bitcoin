class CheckoutController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token, only: [ :webhook ]

  def create
    service = Checkout::Base.for(params[:provider], :create)
    result = service.call(params:, current_user:)

    if result.success?
      case params[:provider]
      when "btcpay"
        # BTCPay flow: Store order ID in session and return JSON for dual-action
        order = Order.find_by(external_id: result.payload.id)
        session[:current_order_id] = order&.id

        redirect_to status_order_path(order)
      else
        redirect_to result.payload.url, allow_other_host: true, status: :see_other
      end
    else
      flash[:alert] = "Payment failed: #{result.error}"
      redirect_to root_path
    end
  end

  def update
    result = Checkout::Stripe::Update.call(current_user:)

    if result.success?
      redirect_to result.payload.url, allow_other_host: true, status: :see_other
    else
      flash[:alert] = "Payment failed. Please try again."
      redirect_to tokens_path
    end
  end

  def success
    result = Checkout::Stripe::Success.call(params[:session_id])

    if result.success?
      flash[:notice] = "Payment successful! Your tokens have been credited."
    else
      flash[:alert] = "Payment failed. Please try again."
    end
    redirect_to root_path
  end

  def webhook
    result = Checkout::Stripe::Webhook.call(request)
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
