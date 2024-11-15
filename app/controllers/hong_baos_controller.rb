class HongBaosController < ApplicationController
  def new
    @hong_bao = HongBao.new(hong_bao_params)
  end

  def show
    @hong_bao = HongBao.find(params[:id])
  end

  def print
    @hong_bao = HongBao.find(params[:id])
    render layout: "print"
  end

  private

  def hong_bao_params
    params.fetch(:hong_bao, {}).permit(:amount, :recipient_name, :message)
  end
end
