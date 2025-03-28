module Client
  class Instagram < Base
    PARAMS = { fields: "id,caption,media_type,media_url,permalink,thumbnail_url,timestamp", access_token: Rails.application.credentials.dig(:instagram, :token) }

    url "https://graph.instagram.com"

    get "/me/media",
      as: :fetch,
      content_type: "multipart/form-data",
      key: "data"

    def me_media
      fetch(**PARAMS)
    end

    def api_key_credential_path
      ""
    end
  end
end
