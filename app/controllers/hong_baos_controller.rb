class HongBaosController < ApplicationController
  def new
    @hong_bao = HongBao.new
  end

  def create
    @hong_bao = HongBao.new(hong_bao_params)

    if @hong_bao.save
      render turbo_stream: turbo_stream.replace(
        "hong_bao_form",
        partial: "success",
        locals: { hong_bao: @hong_bao }
      )
    else
      render :new, status: :unprocessable_entity
    end
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
    params.require(:hong_bao).permit(:amount, :personal_message)
  end
end
