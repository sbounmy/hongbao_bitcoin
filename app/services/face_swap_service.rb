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

    # Télécharger les fichiers Active Storage dans des fichiers temporaires
    source_image = download_tempfile(source_image_blob)
    face_image = download_tempfile(face_to_swap_blob)

    begin
      # Construire le formulaire multipart
      form_data = [
        [ "source_image", source_image ],
        [ "face_image", face_image ],
        [ "webhook", webhook_url ] # Ajout du webhook
      ]

      # Définir le contenu multipart
      request.set_form(form_data, "multipart/form-data")

      Rails.logger.info "Envoi de la requête FaceSwap..."

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      Rails.logger.info "Réponse FaceSwap: #{response.body}"
      JSON.parse(response.body)
    rescue StandardError => e
      { error: e.class.to_s, error_message: e.message }
    ensure
      # Fermeture et suppression des fichiers temporaires
      source_image.close
      source_image.unlink
      face_image.close
      face_image.unlink
    end
  end

  private

  def self.download_tempfile(file)
    tempfile = Tempfile.new([ "image", ".jpg" ])
    tempfile.binmode

    if file.respond_to?(:download)
      # Handle ActiveStorage blob
      tempfile.write(file.download)
    elsif file.respond_to?(:read)
      # Handle uploaded file
      tempfile.write(file.read)
    else
      raise ArgumentError, "Unsupported file type: #{file.class}"
    end

    tempfile.rewind
    tempfile
  end
end
