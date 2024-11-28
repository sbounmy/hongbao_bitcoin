class HongBaosController < ApplicationController
  # skip authentication for new
  allow_unauthenticated_access only: %i[new create]

  def new
    @hong_bao = HongBao.new(amount: params[:amount])
    @papers = Paper.all
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
  end

  def create
    @hong_bao = HongBao.new(hong_bao_params)

    if @hong_bao.save
      if params[:preview] == "true"
        redirect_to hong_bao_path(@hong_bao)
      elsif @hong_bao.payment_method.name == "mt_pelerin"
        render :mt_pelerin_popup, layout: false
      end
    else
      @payment_methods = PaymentMethod.active
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @hong_bao = HongBao.find(params[:id])

    respond_to do |format|
      format.html # renders show.html.erb
      format.btc  # renders show.btc.erb
    end
  end

  def print
    @hong_bao = HongBao.find(params[:id])
    # redirect_to new_hong_bao_path unless @hong_bao.paid?
    render layout: "print"
  end

  private

  def hong_bao_params
    params.fetch(:hong_bao, {}).permit(:amount, :paper_id, :payment_method_id)
  end

  def mt_pelerin_url(hong_bao)
    params = {
      _ctkn: "954139b2-ef3e-4914-82ea-33192d3f43d3",
      em: ERB::Util.url_encode(Current.user.email_address),
      type: "direct-link",
      lang: I18n.locale,
      tab: "buy",
      tabs: "buy",
      net: bitcoin_network,
      nets: bitcoin_network,
      curs: "EUR,USD,SGD",
      ctry: "FR",
      primary: "#F04747",
      success: "#FFB636",
      amount: hong_bao.amount || 50,
      mylogo: ActionController::Base.helpers.asset_url("hongbao-bitcoin-logo-520.png"),
      # Mt Pelerin address validation params
      addr: hong_bao.address,
      code: hong_bao.mt_pelerin_request_code,
      hash: hong_bao.mt_pelerin_request_hash
    }

    "https://buy.mtpelerin.com/?#{params.to_param}"
  end

  def bitcoin_network
    Rails.env.production? ? :bitcoin_mainnet : :bitcoin_testnet
  end
end
