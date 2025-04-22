module Ai
  class ImageGpt < Task
    store :request, accessors: [ :theme_id ], prefix: true
    store :response, accessors: [ :image_url ], prefix: true
  end
end
