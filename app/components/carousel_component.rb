# frozen_string_literal: true

class CarouselComponent < ViewComponent::Base
  attr_reader :media_items

  def initialize(media_items:)
    @media_items = media_items
  end

  def media_tag_for(item, is_thumbnail: false)
    classes = "w-full h-full object-contain bg-gray-50"

    if is_thumbnail
      classes += " object-cover hover:scale-110 transition-transform duration-300 ease-in-out"

      if item[:type] == :youtube
        # Extract the ID from the embed URL provided in the YAML file.
        video_id = item[:url].split("/").last.split("?").first
        thumbnail_url = "https://img.youtube.com/vi/#{video_id}/mqdefault.jpg"
        return image_tag(thumbnail_url, class: classes, alt: "Video thumbnail")
      elsif item[:type] == :google
        return content_tag(:div, class: "#{classes} flex items-center justify-center") do
          heroicon "play-circle", class: "w-10 h-10 text-gray-400"
        end
      end
    end

    case item[:type]
    when :image
      image_tag item[:url], class: classes, alt: "Product media"
    when :youtube
      # Pass the URL directly to the iframe helper with YouTube's specific attributes.
      video_iframe(item[:url], allowfullscreen: true, allow: "autoplay; clipboard-write; encrypted-media; picture-in-picture")
    when :google
      video_iframe(item[:url])
    end
  end

  private

  def video_iframe(src, options = {})
    base_options = {
      class: "w-full aspect-square rounded-lg",
      frameborder: "0"
    }
    iframe_options = base_options.merge(options).merge(src: src)

    content_tag :div, class: "w-full aspect-square flex items-center justify-center" do
      content_tag :iframe, "", iframe_options
    end
  end
end
