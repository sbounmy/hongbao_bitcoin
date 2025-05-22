class BundlesController < ApplicationController
  def create
    @bundle = Bundles::Create.call(user: current_user, params: bundle_params.merge(quality: params[:quality]))
  end

  private

  def bundle_params
    params.require(:bundle).permit(input_items_attributes: [ :input_id, :_destroy, :image, :prompt ])
  end
end
