class HongBaosController < ApplicationController
  allow_unauthenticated_access only: %i[new show index search]

  def index
    @themes = Theme.all
    # Just render the QR scanner view
  end

  def search
    @hong_bao = HongBao.from_scan(params[:hong_bao][:scanned_key])
    if @hong_bao.present?
      session[:private_key] = @hong_bao.private_key if @hong_bao.private_key.present?
      redirect_to hong_bao_path(@hong_bao.address)
    else
      redirect_to hong_baos_path, alert: "Invalid QR code"
    end
  end

  def new
    @hong_bao = HongBao.new(paper_id: params[:paper_id])
    @papers = Paper.active.template.with_attached_image_front.with_attached_image_back
    @payment_methods = PaymentMethod.active.with_attached_logo
    @current_step = (params[:step] || 1).to_i

    @paper =  @papers.find { |p| p.id.to_s == @hong_bao.paper_id.to_s } || @papers.first
    # Only fetch user's papers if they're logged in
    @papers_by_user = current_user ? Paper.where(user: current_user) : Paper.none
    @steps = Step.for_new
    @instagram_posts = cache("instagram_posts", expires_in: 2.hour) { InstagramService.new.fetch_media }
  end

  def show
    @hong_bao = HongBao.from_scan(params[:id])
    @payment_methods = PaymentMethod.active
    @themes = Input::Theme.all
    @current_step = (params[:step] || 1).to_i
    @steps = Step.for_show
  end

  def transfer
  end
end
