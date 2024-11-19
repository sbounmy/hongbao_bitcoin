class HongBaosController < ApplicationController
  def new
    @hong_bao = HongBao.new(hong_bao_params)
  end

  def create
    @hong_bao = HongBao.new(hong_bao_params)

    if @hong_bao.save
      redirect_to mt_pelerin_url(@hong_bao)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @hong_bao = HongBao.find(params[:id])
    redirect_to new_hong_bao_path unless @hong_bao.paid?
  end

  def print
    @hong_bao = HongBao.find(params[:id])
    redirect_to new_hong_bao_path unless @hong_bao.paid?
    render layout: "print"
  end

  private

  def hong_bao_params
    params.fetch(:hong_bao, {}).permit(:amount, :paper_id)
  end

  def mt_pelerin_url(hong_bao)
    params = {
      _ctkn: "954139b2-ef3e-4914-82ea-33192d3f43d3",
      type: "direct-link",
      lang: I18n.locale,
      tab: "buy",
      tabs: "buy",
      net: "bitcoin_mainnet",
      nets: "bitcoin_mainnet",
      curs: "EUR,USD,SGD",
      ctry: "FR",
      primary: "#F04747",
      success: "#FFB636",
      amount: hong_bao.amount || 50,
      mylogo: image_url("hongbao-bitcoin-logo-520.png"),
      # Mt Pelerin address validation params
      addr: hong_bao.public_key,
      code: hong_bao.code,
      hash: hong_bao.generate_mt_pelerin_hash
    }

    "https://buy.mtpelerin.com/?#{params.to_param}"
  end
end
