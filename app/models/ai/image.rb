module Ai
  class Image < Task
    attribute :image_urls, :json, default: []
    store :metadata, accessors: [ :theme_id ]
  end
end
