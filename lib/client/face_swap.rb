module Client
  class FaceSwap < Base
    API_BASE_URL = "https://aifaceswap.io/api/aifaceswap/v1".freeze

    post "/faceswap",
      as: :swap_faces,
      content_type: "multipart/form-data"

    private

    def api_key_credential_path
      [ :faceswap, :api_key ]
    end
  end
end
