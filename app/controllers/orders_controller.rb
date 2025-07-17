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
    
    if params[:content_only].present?
      render Orders::StatusComponent.new(order: @order), layout: false
    end
  end

end
