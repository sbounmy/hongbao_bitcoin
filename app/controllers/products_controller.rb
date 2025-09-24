class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @products = Product.published.ordered.includes(variants: { images_attachments: :blob })
  end

  def show
    @product = Product.published.includes(variants: { images_attachments: :blob }).find_by(slug: params[:pack])

    unless @product
      redirect_to products_path, alert: "Product not found"
      return
    end

    @selected_color = params[:color] || "red"
    @selected_variant = @product.variant_for_color(@selected_color) || @product.default_variant

    # For compatibility with existing views
    @products = Product.published.ordered
  end
end