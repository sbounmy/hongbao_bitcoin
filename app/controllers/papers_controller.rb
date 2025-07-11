class PapersController < ApplicationController
  layout "offline", only: [ :show ]
  allow_unauthenticated_access only: [ :show, :index ]
  helper_method :testnet?
  before_action :set_network

  def index
    # Will be used to list available styles and papers
    @styles = Input::Style.ordered.with_attached_image
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
  end

  def show
    @paper = Paper.find(params[:id])
    @hong_bao = HongBao.new
    @payment_methods = PaymentMethod.active.order(order: :asc).with_attached_logo
    @steps = Step.for_new
    @current_step = (params[:step] || 1).to_i
  end

  private

  def testnet?
    value = ActiveModel::Type::Boolean.new.cast(params[:testnet])
    value.nil? ? false : value
  end

  def set_network
    Current.network = testnet? ? :testnet : :mainnet
  end
end
