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

    def processing?
      !item.image_front.attached? || !item.image_back.attached?
    end

    def render_face(image_url:)
      background_url = processing? ? original_image_url : image_url
      aspect_ratio = item.theme&.aspect_ratio || "150/75"

      tag.div class: "w-full aspect-[#{aspect_ratio}] relative rounded-lg overflow-hidden" do
        background_classes = [ "absolute inset-0 bg-cover bg-center" ]
        background_classes << "blur-md" if processing?
        concat(
          tag.div(
            class: background_classes.join(" "),
            style: background_style(background_url)
          )
        )

        concat(
          tag.div(class: "relative h-full") do
            if processing?
              concat(
                tag.div(class: "absolute inset-0 flex items-center justify-center p-4 text-white") do
                  tag.div(class: "flex flex-col items-center gap-2 text-center") do
                    concat(tag.p("Generating paper... this will take approx. 1 minute!", class: "font-medium drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,0.8)]"))
                    concat(render(ProgressBarComponent.new(animated: true, duration: 60, class: "w-full")))
                  end
                end
              )
            end

            concat(
              tag.div(class: "absolute bottom-0 left-0 w-full h-16 bg-gradient-to-t from-black/80 to-transparent") do
                tag.div item.name, class: "absolute bottom-2 left-3 text-white text-lg font-medium"
              end
            )
          end
        )
      end
    end

    def background_style(image_url)
      "background-image: url('#{image_url}')" if image_url.present?
    end

    def original_image_url
      input_image = item.bundle&.input_items&.last&.image
      url_for(input_image) if input_image&.attached?
    end

    def image_front_url
      item.image_front.attached? ? url_for(item.image_front) : ""
    end

    def image_back_url
      item.image_back.attached? ? url_for(item.image_back) : ""
    end
  end
end
