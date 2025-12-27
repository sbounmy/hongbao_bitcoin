class PapersController < ApplicationController
  layout :set_layout
  allow_unauthenticated_access only: [ :index, :show, :new, :new2, :explore ]
  helper_method :testnet?
  before_action :set_network

  def index
    @styles = Input::Style.with_attached_image
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)

    # Processing papers for current user (generating section)
    @processing_papers = current_user&.papers&.processing&.recent || Paper.none
  end

  def show
    @paper = Paper.find(params[:id])
    @paper.increment_views!(session)
    @hong_bao = HongBao.new
    @payment_methods = PaymentMethod.active.by_position.with_attached_logo
    @steps = Step.for_new
    @current_step = (params[:step] || 1).to_i
  end

  def new
    @theme = Input::Theme.find_by(id: params[:theme_id]) || Input::Theme.first
    @frame = @theme.frame_object
    @current_step = 1

    # Build a "virtual" paper object for view compatibility
    @paper = Paper.new
    @paper.elements = @theme.ai

    # Embed theme images as base64 for offline use
    @template_front_base64 = helpers.base64_url(@theme.image_front)
    @template_back_base64 = helpers.base64_url(@theme.image_back)
    @portrait_config = @theme.portrait_config

    # Photo sheet data
    @styles = Input::Style.by_position.with_attached_image
    @pagy, @recent_photos = pagy_countless(
      InputItem.distinct_images_for(paper_scope),
      limit: 20
    )
  end

  # Alias for backwards compatibility
  def new2
    new
    render :new
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
    Papers::Update.call(paper: @paper, params: paper_params)

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
      input_item_theme_attributes: [ :id, :input_id ],
      input_item_style_attributes: [ :id, :input_id ],
      input_items_attributes: [ :id, :input_id, :image, :blob_id, :_destroy ]
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


  def set_layout
    case action_name
    when "show", "new", "new2"
      "offline"
    when "index", "explore", "edit"
      "main"
    end
  end
end
