class CheckoutController < ApplicationController
  allow_unauthenticated_access
  def create
    # Create a Stripe Checkout Session
    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [ {
        price: params[:price_id],
        quantity: 1
      } ],
      mode: "payment",
      success_url: CGI.unescape(success_checkout_index_url(session_id: "{CHECKOUT_SESSION_ID}")), # so {CHECKOUT_SESSION_ID} is not escaped
      cancel_url: cancel_checkout_index_url
    )

    # Redirect to Stripe Checkout
    redirect_to session.url, allow_other_host: true
  end

  def success
    # Handle successful payment
    @checkout_session = Stripe::Checkout::Session.retrieve(params[:session_id])
    Rails.logger.info("checkout_session: #{@checkout_session.inspect}")
    @user = User.find_by(email: @checkout_session.customer_details.email)
    Rails.logger.info("user: #{@user.inspect}")
    if !authenticated?
      @user ||= User.create!(email: @checkout_session.customer_details.email, password: SecureRandom.hex(16))
      start_new_session_for(@user)
    end
    flash[:notice] = "Payment successful! Your tokens have been credited."
    redirect_to v2_path
  end

  def cancel
    # Handle cancelled payment
    flash[:alert] = "Payment cancelled."
    redirect_to root_path
  end
end
