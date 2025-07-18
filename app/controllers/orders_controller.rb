class OrdersController < ApplicationController
  def index
    @orders = current_user.orders.includes(:line_items, :tokens).order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find(params[:id])
  end
end
