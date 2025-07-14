class PapersController < ApplicationController
  layout :set_layout
  allow_unauthenticated_access
  helper_method :testnet?
  before_action :set_network

  def index
    # Will be used to list available styles and papers
    @styles = Input::Style.by_position.with_attached_image
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
  end

  def index_3
    @styles = Input::Style.with_attached_image
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
  end

  def show
    @paper = Paper.find(params[:id])
    @hong_bao = HongBao.new
    @payment_methods = PaymentMethod.active.by_position.with_attached_logo
    @steps = Step.for_new
    @current_step = (params[:step] || 1).to_i
  end

  def new
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
    @styles = Input::Style.with_attached_image
    @themes = Input::Theme.with_attached_image
    @papers = paper_scope.active.recent.with_attached_image_front.with_attached_image_back
  end

  def explore
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
  end

  private

  def paper_scope
    current_user ? current_user.papers : Paper
  end

  def testnet?
    value = ActiveModel::Type::Boolean.new.cast(params[:testnet])
    value.nil? ? false : value
  end

  def set_network
    Current.network = testnet? ? :testnet : :mainnet
  end

  private

  def set_layout
    case action_name
    when "show"
      "offline"
    when "new", "index_3", "explore"
      "main"
    else
      "application"
    end
  end
end
