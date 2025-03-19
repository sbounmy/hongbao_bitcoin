require "tempfile"
require "net/http"
require "uri"
# require "http"
require "open-uri"

class FaceSwap < ApplicationService
  API_URL = "https://aifaceswap.io/api/aifaceswap/v1/faceswap".freeze
  API_KEY = Rails.application.credentials.dig(:faceswap, :api_key)
  WEBHOOK_URL = "https://stephane.hongbaob.tc/ai/face_swap/done".freeze

  def call(image, face)
    uri = URI(API_URL)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{API_KEY}"

    # Get binary data directly
    source_data = image.download
    face_data = face.download

    # Build multipart form
    form_data = [
      [ "source_image", source_data, { filename: "source.jpg" } ],
      [ "face_image", face_data, { filename: "face.jpg" } ],
      [ "webhook", WEBHOOK_URL ]
    ]
    request.set_form(form_data, "multipart/form-data")

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    success JSON.parse(response.body)
  end
end
