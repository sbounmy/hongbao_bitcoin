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
    @bitcoin_price = BitcoinPrice.new bitcoin_price_params
    @totals = @bitcoin_price.calculate_totals
    @birthdate_price_btc = @bitcoin_price.birthdate_price_btc(bitcoin_price_params[:birthdate])
    @christmas_price_btc = @bitcoin_price.christmas_price_btc(bitcoin_price_params[:birthdate])
    @lunar_new_year_price_btc = @bitcoin_price.lunar_new_year_price_btc(bitcoin_price_params[:birthdate])
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

  def bitcoin_price_params
    params.require(:bitcoin_price).permit(:birthdate, :birthday_amount, :christmas_amount, :cny_amount)
  rescue ActionController::ParameterMissing
    { birthdate: 10.years.ago.to_date, birthday_amount: 500, christmas_amount: 500, cny_amount: 500 }
  end
end
