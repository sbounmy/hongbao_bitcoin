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
end
