class HongBaosController < ApplicationController
  allow_unauthenticated_access only: %i[new show form index search utxos transfer]
  before_action :set_network, only: %i[show form utxos]
  layout :set_layout

  def index
    # Just render the QR scanner view
  end

  def search
    result = HongBaos::Scanner.call(params[:hong_bao][:scanned_key])

    if result.success?
      hong_bao = result.payload
      session[:private_key] = hong_bao.private_key if hong_bao.private_key.present?
      redirect_to addr_path(hong_bao.address)
    else
      error_message = result.error.respond_to?(:user_message) ?
                      result.error.user_message :
                      "Invalid QR code: #{result.error.message}"
      redirect_to hong_baos_path, alert: error_message
    end
  end

  def new
    @hong_bao = HongBao.new(paper_id: params[:paper_id])
    @papers = Paper.active.template.with_attached_image_front.with_attached_image_back
    @payment_methods = PaymentMethod.active.order(order: :asc).with_attached_logo
    @current_step = (params[:step] || 1).to_i

    @paper =  @papers.find { |p| p.id.to_s == @hong_bao.paper_id.to_s } || @papers.first
    # Only fetch user's papers if they're logged in
    @papers_by_user = current_user ? Paper.where(user: current_user) : Paper.none
    @steps = Step.for_new
    @instagram_posts = cache("instagram_posts", expires_in: 2.hour) { InstagramService.new.fetch_media }
  end

  def show
    result = HongBaos::Scanner.call(params[:id])

    if result.success?
      @hong_bao = result.payload
    else
      redirect_to hong_baos_path, alert: result.error.user_message
    end
  end

  def form
    @hong_bao = HongBao.from_scan(params[:id])
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
    @steps = Step.for_show
  end

  def transfer
    raw_hex = params.require(:raw_hex)
    network = params.require(:network)
    Current.network = network.to_sym if network.present?

    response = Client::BlockstreamApi.new(dev: Current.testnet?).post_transaction(body: raw_hex)

    if response.is_a?(String)
      render json: { txid: response }, status: :ok
    else
      render json: { error: "Failed to broadcast transaction: #{response.body}" }, status: :unprocessable_entity
    end
  end

  def utxos
    @hong_bao = HongBao.from_scan(params[:id])
    @utxos = @hong_bao.balance.utxos_for_transaction(true)
  end

  private

  def set_network
    Current.network = Current.network_from_key(params[:id] || params[:hong_bao][:scanned_key])
  end
  def set_layout
    if request.format.html?
      "offline"
    else
      false
    end
  end
end
