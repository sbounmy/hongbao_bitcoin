class ProductsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_product, only: :show

  def index
    @products = Shopify::Product.all
  end

  def show
    # Find product from Shopify by ID
    @product = Shopify::Product.find(params[:id])

    unless @product
      redirect_to products_path, alert: "Product not found"
      return
    end

    # Handle color selection for variants
    @selected_color = params[:color] || "red"

    # Find variant by color if product has variants
    if @product.variants && @product.variants.any?
      @selected_variant = @product.variants.find do |variant|
        variant.selected_options&.any? { |opt| opt.name.downcase == "color" && opt.value.downcase == @selected_color.downcase }
      end || @product.variants.first
    else
      # Fallback if no variants
      @selected_variant = OpenStruct.new(
        title: @product.title,
        price: @product.variants&.first&.price || "0",
        sku: @product.variants&.first&.sku,
        id: @product.variants&.first&.id
      )
    end
  end

  private

  def set_product
    # This is called before show action
    # The actual product finding is done in the show action
  end
end
