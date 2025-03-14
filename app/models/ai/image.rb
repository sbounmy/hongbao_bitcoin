module Ai
  class Image < Task
    attribute :image_urls, :json, default: []
    store :metadata, accessors: [ :theme_id ]

    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "Ai::Image")
    end
  end
end
