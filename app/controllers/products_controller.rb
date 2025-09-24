class ProductsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_product, only: :show

  def index
    @products = Product.published.ordered.includes(variants: { images_attachments: :blob })
  end

  def show
    @selected_color = params[:color] || "red"
    @selected_variant = @product.variant_for_color(@selected_color) || @product.default_variant
    @products = Product.published.ordered # For compatibility with existing views
  end

  private

  def set_product
    @product = Product.published.includes(variants: { images_attachments: :blob }).friendly.find(params[:pack])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "Product not found"
  end
end
