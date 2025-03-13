module Ai
  class Image < Task
    attribute :image_urls, :json, default: []
  end
end
