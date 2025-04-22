module Client
  class FaceSwap < Base
    url "https://aifaceswap.io/api/aifaceswap/v1"

    post "/faceswap",
      as: :swap_faces,
      content_type: "multipart/form-data",
      key: "data"

    private

    def api_key_credential_path
      [ :faceswap, :api_key ]
    end
  end
end
