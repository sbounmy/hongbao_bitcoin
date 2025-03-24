module Ai
  class FaceSwap < Task
    store :request, accessors: [ :paper_id, :image ]
    store :response, accessors: [ :image_url ], prefix: true
  end
end
