class CheckoutController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token, only: [ :webhook ]

  before_action :set_variant_and_product, only: [ :new ]

  def new
    case params[:provider]
    when "btcpay"
      render :btcpay_form
    else
      redirect_to root_path
    end
  end

  def create
    service = Checkout::Base.for(params[:provider], :create)
    result = service.call(params:, current_user:)

    if result.success?
      redirect_to result.payload.url, allow_other_host: true, status: :see_other
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
    service = Checkout::Base.for(params[:provider] || "stripe", :success)
    result = service.call(params[:session_id])

    if result.success?
      set_success_flash_message
    else
      flash[:alert] = "Payment processing. Please check your email for confirmation."
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

  private

  def set_variant_and_product
    @variant = Variant.find_by(id: params[:variant_id])
    @product = @variant&.product
  end

  def set_success_flash_message
    if authenticated?
      flash[:notice] = "Payment successful! Your tokens have been credited."
    else
      flash[:notice] = "Payment successful! An account has been created for you. Please check your email for further instructions."
    end
  end
end
