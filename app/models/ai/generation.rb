module Ai
  class Generation < Task
    attribute :image_urls, :json, default: []
    has_many_attached :generated_images, dependent: :destroy
  end
end
