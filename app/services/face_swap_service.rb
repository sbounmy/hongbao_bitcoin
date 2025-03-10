require "tempfile"
require "net/http"
require "uri"
# require "http"
require "open-uri"

class FaceSwapService
  API_URL = "https://aifaceswap.io/api/aifaceswap/v1/faceswap".freeze
  API_KEY = Rails.application.credentials.dig(:faceswap, :api_key)

  def self.swap_faces(source_image_blob, face_to_swap_blob, webhook_url)
    uri = URI(API_URL)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{API_KEY}"

    # Get binary data directly
    source_data = source_image_blob.download
    face_data = face_to_swap_blob.read

    # Build multipart form
    form_data = [
      [ "source_image", source_data, { filename: "source.jpg" } ],
      [ "face_image", face_data, { filename: "face.jpg" } ],
      [ "webhook", webhook_url ]
    ]

    # Définir le contenu multipart
    request.set_form(form_data, "multipart/form-data")

    Rails.logger.info "Envoi de la requête FaceSwap..."

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    Rails.logger.info "Réponse FaceSwap: #{response.body}"
    JSON.parse(response.body)
  end
end
