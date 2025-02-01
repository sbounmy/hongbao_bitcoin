class HongBaosController < ApplicationController
  allow_unauthenticated_access only: %i[new show index search]

  def index
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
    @papers = Paper.active
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
    @steps = [ "Design", "Print", "Top up" ]
  end

  def show
    @hong_bao = HongBao.from_scan(params[:id])
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
    @steps = [ "Balance", "Private key", "Destination", "Complete" ]
  end

  def transfer
  end
end
