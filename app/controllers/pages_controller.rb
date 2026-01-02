class PagesController < ApplicationController
  allow_unauthenticated_access
  def index
    @users = User.joins(:avatar_attachment).with_attached_avatar.limit(8)
    @saved_hong_baos = (User.find_by(email: "stephane@hackerhouse.paris")&.saved_hong_baos || SavedHongBao.none).order(gifted_at: :desc)
    @quotes = Content::Quote.with_hongbao_product.with_attached_avatar
    @simulation = Simulation.new
    @simulation_result = Simulations::Create.call(@simulation.to_service_params.merge(stats_only: true))
    @latest_newsletter = Substack::Feed.call.first
    @product = Product.published.ordered.includes(variants: { images_attachments: :blob }, images_attachments: :blob).last
  end

  def pricing
    @product = Product.published.ordered.includes(variants: { images_attachments: :blob }, images_attachments: :blob).last
  end

  def instructions
    render layout: false
  end
end
