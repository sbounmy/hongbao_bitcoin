# frozen_string_literal: true

class CarouselComponent < ViewComponent::Base
  attr_reader :media_items

  def initialize(media_items:)
    @media_items = media_items
  end

  def media_tag_for(item)
    case item[:type]
    when :image
      image_tag item[:url], class: "w-full h-full object-contain", alt: "Product media"
    when :youtube, :google
      content_tag :div, class: "w-full h-full flex items-center justify-center" do
        content_tag :iframe, "",
          src: item[:url],
          class: "w-full h-full aspect-video rounded-lg",
          frameborder: "0",
          allowfullscreen: true,
          allow: "autoplay; clipboard-write; encrypted-media; picture-in-picture"
      end
    when :video
      video_tag item[:sources], autoplay: true, muted: true, loop: true, playsinline: true, class: "w-full h-full object-contain"
    end
  end
end
