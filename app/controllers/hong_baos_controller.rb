class HongBaosController < ApplicationController
  allow_unauthenticated_access only: %i[new show index transfer]

  def index
    # Just render the QR scanner view
  end

  def new
    @hong_bao = HongBao.generate(paper_id: params[:paper_id])
    @papers = Paper.active
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
  end

  def show
    @hong_bao = HongBao.from_scan(params[:id])
  end

  private

  def transfer_params
    params.require(:hong_bao).permit(:to_address, :amount, :mnemonic)
  end
end
