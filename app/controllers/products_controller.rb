class ProductsController < ApplicationController
  def index
    @products = StripeService.fetch_products
  end

  def show
    @products = StripeService.fetch_products
    @product = @products.find { |p| p[:slug] == params[:pack] }
    @selected_color = params[:color] || "red"

    redirect_to products_path unless @product
  end
end