require "net/http"
require "json"

class InstagramService
  INSTAGRAM_API_URL = "https://graph.instagram.com".freeze

  def initialize
    @access_token = Rails.application.credentials.instagram[:token]
  end

  def fetch_media
    uri = URI("#{INSTAGRAM_API_URL}/me/media")
    params = {
      fields: "id,caption,media_type,media_url,permalink,thumbnail_url,timestamp",
      access_token: @access_token
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    return [] unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("data", [])
  rescue JSON::ParserError, SocketError, Net::HTTPError => e
    Rails.logger.error("Instagram API Error: #{e.message}")
    []
  end

  private

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      Rails.logger.error("Instagram API Error: #{response.code} - #{response.message}")
      { "data" => [] }
    end
  end
end
