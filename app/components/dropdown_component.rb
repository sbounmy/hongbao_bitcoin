class DropdownComponent < ApplicationComponent
  attr_reader :items, :current_item, :path_helper, :button_style

  def initialize(items:, current_item:, **options)
    @items = items
    @current_item = current_item
    @path_helper = options[:path_helper]
    @button_style = options[:button_style] || {}
    @title = options[:title]
  end

  def title?
    @title
  end
  private

  def item_path(item)
    return send(path_helper, item.slug) if path_helper && item.respond_to?(:slug)
    "#"
  end

  def item_title(item)
    return item.name if item.respond_to?(:name)
    item.to_s
  end

  def item_image(item)
    return image_tag(item.image_hero.variant(resize_to_fill: [ 24, 24 ]), class: "w-6 h-6 rounded") if item.respond_to?(:image_hero) && item.image_hero.attached?
    nil
  end

  def button_text_color
    button_style.fetch(:text_color, "currentColor")
  end

  def button_background_color
    button_style.fetch(:background_color, "transparent")
  end
end
