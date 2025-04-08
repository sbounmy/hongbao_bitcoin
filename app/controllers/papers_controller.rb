class PapersController < ApplicationController
  allow_unauthenticated_access only: :show
  def show
    @paper = Paper.find(params[:id])
    @hong_bao = HongBao.new
    @payment_methods = PaymentMethod.all
    @steps = Step.for_show_v2
    @current_step = (params[:step] || 1).to_i
  end
end
