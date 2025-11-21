class PapersController < ApplicationController
  layout :set_layout
  allow_unauthenticated_access only: [ :index, :show, :new, :create, :explore, :update ]
  helper_method :testnet?
  before_action :set_network

  def index
    @styles = Input::Style.with_attached_image
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
  end

  def show
    @paper = Paper.find(params[:id])
    @paper.increment_views!
    @hong_bao = HongBao.new
    @payment_methods = PaymentMethod.active.by_position.with_attached_logo
    @steps = Step.for_new
    @current_step = (params[:step] || 1).to_i
  end

  def new
    @paper = Paper.new
    @paper.input_items.build
    @styles = Input::Style.by_position.with_attached_image
    @themes = Input::Theme.by_position.with_attached_image
    @papers = paper_scope.active.recent.with_attached_image_front.with_attached_image_back
  end

  def create
    @paper = Papers::Create.call(
      user: current_user,
      params: paper_params
    )
    redirect_to edit_paper_path(@paper)
  end

  def edit
    @paper = current_user.papers.find params[:id]
  end

  def update
    @paper = current_user.papers.find(params[:id])
    Papers::Update.call(paper: @paper, theme_id: params[:theme_id])

    respond_to do |format|
      format.turbo_stream { head :ok }  # Broadcasting handles the update
      format.html { redirect_to edit_paper_path(@paper) }
    end
  end

  def explore
    @pagy, @papers = pagy_countless(
      Paper.active.recent.with_attached_image_front.with_attached_image_back,
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def like
    @paper = Paper.find(params[:id])
    @paper.like_toggle!(current_user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @paper }
    end
  end

  private

  def paper_params
    params.require(:paper).permit(
      input_item_theme_attributes: [:input_id],
      input_item_style_attributes: [:input_id],
      input_items_attributes: [:input_id, :image, :_destroy]
    )
  end

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
    when "new", "index", "explore", "edit"
      "main"
    else
      "application"
    end
  end
end
