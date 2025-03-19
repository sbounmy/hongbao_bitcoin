module Ai
  class Image < Task
    store :response, accessors: [ :image_urls ], prefix: true
    store :request, accessors: [ :theme_id ], prefix: true
  end
end
