# frozen_string_literal: true

module Papers
  class ItemComponent < ApplicationComponent
    attr_reader :item, :broadcast

    def initialize(item:, broadcast: true)
      @item = item
      @broadcast = broadcast
      super
    end

    def cache_key
      item.cache_key
    end

    private

    def render_face(image_url:)
      tag.div class: "w-full aspect-[170/90] bg-cover bg-center rounded-lg",
              style: background_style(image_url) do
        tag.div class: "absolute bottom-0 left-0 w-full h-16 bg-gradient-to-t from-black/80 to-transparent" do
          tag.div item.name, class: "absolute bottom-2 left-3 text-white text-lg font-medium"
        end
      end
    end

    def background_style(image_url)
      "background-image: url('#{image_url}')" if image_url.present?
    end

    def image_front_url
      item.image_front.attached? ? url_for(item.image_front) : ""
    end

    def image_back_url
      item.image_back.attached? ? url_for(item.image_back) : ""
    end
  end
end
