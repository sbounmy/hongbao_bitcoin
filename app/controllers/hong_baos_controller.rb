class HongBaosController < ApplicationController
  # skip authentication for new
  allow_unauthenticated_access only: %i[new show]

  def new
    @hong_bao = HongBao.new(paper_id: params[:paper_id])
    @papers = Paper.active
    @payment_methods = PaymentMethod.active
    @current_step = (params[:step] || 1).to_i
  end
end
