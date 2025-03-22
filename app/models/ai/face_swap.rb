module Ai
  class FaceSwap < Task
    # Add any FaceSwap specific validations or methods

    store :request, accessors: [ :paper_id, :image ]
  end
end
