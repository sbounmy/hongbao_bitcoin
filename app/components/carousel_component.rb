# frozen_string_literal: true

class CarouselComponent < ViewComponent::Base
  attr_reader :media_items

  def initialize(media_items:)
    @media_items = media_items
  end

  def media_tag_for(item)
    case item[:type]
    when :image
      image_tag item[:url], class: "w-full aspect-square object-contain bg-gray-50", alt: "Product media"
    when :youtube, :google
      content_tag :div, class: "w-full aspect-square flex items-center justify-center" do
        content_tag :iframe, "",
          src: item[:url],
          class: "w-full aspect-square rounded-lg",
          frameborder: "0",
          allowfullscreen: true,
          allow: "autoplay; clipboard-write; encrypted-media; picture-in-picture"
      end
    when :video
      video_tag item[:sources], autoplay: true, muted: true, loop: true, playsinline: true, class: "w-full h-full object-contain"
    end
  end
end
