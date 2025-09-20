class SavedHongBaosController < ApplicationController
  before_action :set_saved_hong_bao, only: [ :show, :destroy ]
  before_action :set_network, only: [ :create, :show ]

  def index
    @saved_hong_baos = current_user.saved_hong_baos.order(created_at: :desc)
    @total_balance_btc = @saved_hong_baos.sum(&:btc)
    @total_balance_usd = @saved_hong_baos.sum(&:usd)
  end

  def new
    @saved_hong_bao = current_user.saved_hong_baos.build
    @saved_hong_bao.address = params[:address] if params[:address].present?
  end

  def create
    @saved_hong_bao = current_user.saved_hong_baos.build(saved_hong_bao_params)

    if @saved_hong_bao.save
      redirect_to saved_hong_baos_path, notice: "Hong Bao saved successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @balance = @saved_hong_bao.balance
    @transactions = @balance.transactions
  end

  def destroy
    @saved_hong_bao.destroy
    redirect_to saved_hong_baos_path, notice: "Hong Bao removed from saved list."
  end

  def scan
    result = HongBaos::Scanner.call(params[:scanned_key])

    if result.success?
      hong_bao = result.payload
      # Pre-fill the form with scanned address
      @saved_hong_bao = current_user.saved_hong_baos.build(address: hong_bao.address)
      render :new
    else
      redirect_to new_saved_hong_bao_path, alert: "Invalid QR code. Please try again or enter the address manually."
    end
  end

  private

  def set_saved_hong_bao
    @saved_hong_bao = current_user.saved_hong_baos.find(params[:id])
  end

  def saved_hong_bao_params
    params.require(:saved_hong_bao).permit(:name, :address, :notes)
  end

  def set_network
    Current.network = Current.network_from_key(saved_hong_bao_params[:address])
  end
end
