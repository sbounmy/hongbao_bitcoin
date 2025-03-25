# frozen_string_literal: true

module Papers
  class ItemComponent < ApplicationComponent
    attr_reader :paper

    def initialize(paper:)
      @paper = paper
      super
    end

    def cache_key
      @paper
    end

    private

    def paper_data_attributes
      {
        'front-elements-value': paper.front_elements.to_json,
        'back-elements-value': paper.back_elements.to_json,
        'front-image-value': front_image_url,
        'back-image-value': back_image_url
      }.map { |key, value| "data-#{key}=\"#{value}\"" }.join(" ").html_safe
    end

    def render_face(image_url:)
      tag.div class: "w-full aspect-[170/90] bg-cover bg-center rounded-lg",
              style: background_style(image_url) do
        tag.div class: "absolute bottom-0 left-0 w-full h-16 bg-gradient-to-t from-black/80 to-transparent" do
          tag.div paper.name, class: "absolute bottom-2 left-3 text-white text-lg font-medium"
        end
      end
    end

    def background_style(image_url)
      "background-image: url('#{image_url}')" if image_url.present?
    end

    def front_image_url
      paper.image_front.attached? ? url_for(paper.image_front) : ""
    end

    def back_image_url
      paper.image_back.attached? ? url_for(paper.image_back) : ""
    end
  end
end
