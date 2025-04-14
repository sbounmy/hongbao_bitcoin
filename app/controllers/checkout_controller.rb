class CheckoutController < ApplicationController
  allow_unauthenticated_access
  def create
    # Create a Stripe Checkout Session
    session = Stripe::Checkout::Session.create(checkout_params)
    # Redirect to Stripe Checkout
    redirect_to session.url, allow_other_host: true
  end

  def success
    result = Checkout::Success.call(params[:session_id], authenticated: authenticated?)

    if result.success?
      flash[:notice] = "Payment successful! Your tokens have been credited."
      start_new_session_for(result.payload)
    else
      flash[:alert] = "Payment failed. Please try again."
    end
    redirect_to v2_path
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

  private

  def checkout_params
    p = {
      payment_method_types: [ "card" ],
      line_items: [ {
        price: params[:price_id],
        quantity: 1
      } ],
      mode: "payment",
      success_url: CGI.unescape(success_checkout_index_url(session_id: "{CHECKOUT_SESSION_ID}")), # so {CHECKOUT_SESSION_ID} is not escaped
      cancel_url: cancel_checkout_index_url
    }
    if authenticated?
      p[:customer] = current_user.stripe_customer_id if current_user.stripe_customer_id
      p[:customer_email] = current_user.email
    end
    p
  end
end
