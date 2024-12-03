class HongBaosController < ApplicationController
  # skip authentication for new
  # allow_unauthenticated_access only: %i[new create]

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
end
