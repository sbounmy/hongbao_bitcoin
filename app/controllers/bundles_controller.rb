class BundlesController < ApplicationController
  def create
    @bundle = current_user.bundles.create!(bundle_params)
  end

  private

  def bundle_params
    params.require(:bundle).permit(input_items_attributes: [ :input_id, :_destroy ])
  end
end
