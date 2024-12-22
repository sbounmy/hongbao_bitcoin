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
    @hong_bao = HongBao.generate(paper_id: params[:paper_id])
    @papers = Paper.active
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
    @simulator = BitcoinPrice.new simulator_params
  end

  def show
    @hong_bao = HongBao.from_scan(params[:id])
    @payment_methods = PaymentMethod.active
  end

  def transfer
    @hong_bao =  HongBao.from_private_key(session[:private_key])
    @payment_methods = PaymentMethod.active

    if @hong_bao.transfer(transfer_params)
      redirect_to hong_bao_path(@hong_bao.address), notice: "Funds transferred successfully"
    else
      render :show
    end
  end

  private

  def transfer_params
    params.require(:hong_bao).permit(:to_address, :payment_method_id)
  end
  def simulator_params
    (params[:simulator_bitcoin] || {})
  end
end
