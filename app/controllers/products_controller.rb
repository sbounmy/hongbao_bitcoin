class ProductsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_product, only: :show

  def index
    @products = Product.published.ordered.includes(variants: { images_attachments: :blob }, images_attachments: :blob)
  end

  def show
  end

  private

  def set_product
    if params[:pack].present? && params[:pack] != params[:slug]
      render turbo_stream: turbo_stream.action(:redirect, product_path(slug: params[:pack], pack: params[:pack], variant_id: params[:variant_id]))
      return
    end
   @product = Product.published.includes(variants: { images_attachments: :blob }, images_attachments: :blob).friendly.find(params[:slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "Product not found"
  end
end
