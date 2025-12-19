class InputItemsController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  def index
    @pagy, @input_items = pagy_countless(
      input_items_scope,
      limit: 20
    )

    respond_to do |format|
      format.turbo_stream
    end
  end

  # POST /input_items - Create InputItem with AI generation
  def create
    @input_item = InputItem.new(input_item_params)

    if @input_item.save
      # Queue AI generation job if style is selected
      if @input_item.input.is_a?(Input::Style)
        GenerateStyledPortraitJob.perform_later(@input_item.id)
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash_error", locals: { message: @input_item.errors.full_messages.join(", ") })
        end
        format.html { redirect_back fallback_location: root_path, alert: @input_item.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def input_items_scope
    scope = InputItem.where(paper: paper_scope)

    # Filter by input type if provided (e.g., ?type=image)
    if params[:type].present?
      input_type = "Input::#{params[:type].classify}"
      scope = scope.joins(:input).where(inputs: { type: input_type })
    end

    # For images: distinct by checksum to avoid duplicates
    if params[:type] == "image"
      scope = distinct_by_checksum(scope)
    else
      scope = scope.includes(image_attachment: :blob).order(created_at: :desc)
    end

    scope
  end

  # Distinct photos by checksum - same image content won't appear twice
  def distinct_by_checksum(scope)
    latest_ids = scope
      .joins(image_attachment: :blob)
      .group("active_storage_blobs.checksum")
      .select("MAX(input_items.id) as id")
      .map(&:id)

    InputItem
      .where(id: latest_ids)
      .includes(image_attachment: :blob)
      .order(created_at: :desc)
  end

  def paper_scope
    current_user ? current_user.papers : Paper
  end

  def input_item_params
    params.require(:input_item).permit(:input_id, :blob_id, :image)
  end
end
