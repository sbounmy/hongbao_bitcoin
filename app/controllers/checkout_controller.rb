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
      success_url: success_checkout_index_url,
      cancel_url: cancel_checkout_index_url
    )

    # Redirect to Stripe Checkout
    redirect_to session.url, allow_other_host: true
  end

  def success
    # Handle successful payment
    flash[:notice] = "Payment successful! Your tokens have been credited."
    redirect_to root_path
  end

  def cancel
    # Handle cancelled payment
    flash[:alert] = "Payment cancelled."
    redirect_to root_path
  end
end
