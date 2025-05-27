class PapersController < ApplicationController
  allow_unauthenticated_access only: [ :show, :index ]

  def index
    # Will be used to list available styles and papers
    @styles = Input::Style.with_attached_image
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
  end
  def show
    @paper = Paper.find(params[:id])
    @hong_bao = HongBao.new
    @payment_methods = PaymentMethod.all
    @steps = Step.for_new
    @current_step = (params[:step] || 1).to_i
  end
end
