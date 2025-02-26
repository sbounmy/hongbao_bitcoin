module Webhooks
  class FaceSwapController < ApplicationController
    skip_before_action :verify_authenticity_token

    def callback
      data = params.permit(:success, :type, :task_id, :result_image)

      # Traite les données (ex : enregistrer le résultat en base)
      Rails.logger.info "Face swap terminé : #{data.to_h}"

      head :ok
    end
  end
end
