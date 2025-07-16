class OrdersController < ApplicationController
  allow_unauthenticated_access only: [ :status ]

  def index
    @orders = current_user.orders.includes(:line_items, :tokens).order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find(params[:id])
  end

  def status
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html # Show the status page
      format.json { render json: order_status_json }
    end
  end

  private

  def order_status_json
    {
      id: @order.id,
      state: @order.state,
      payment_provider: @order.payment_provider,
      total_amount: @order.total_amount,
      currency: @order.currency,
      external_id: @order.external_id,
      created_at: @order.created_at,
      updated_at: @order.updated_at,
      user_email: @order.user&.email,
      shipping_name: @order.shipping_name,
      line_items_count: @order.line_items.count,
      tokens_count: @order.tokens.count,
      dashboard_url: @order.payment_provider_dashboard_url
    }
  end
end
