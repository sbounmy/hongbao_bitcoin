class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @products = Product.published.ordered.with_variants
  end

  def show
    @product = Product.published.with_variants.friendly.find(params[:slug])
    @selected_variant = @product.find_variant_by_param(params[:option]) || @product.default_variant
    @selected_option = @product.variant_url_param(@selected_variant)
  end
end
