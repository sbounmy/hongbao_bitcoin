class DropdownComponent < ViewComponent::Base
  attr_reader :items, :current_item, :path_helper, :button_style

  def initialize(items:, current_item:, path_helper: nil, button_style: {})
    @items = items
    @current_item = current_item
    @path_helper = path_helper
    @button_style = button_style
  end

  private

  def item_path(item)
    return send(path_helper, item.path) if path_helper && item.respond_to?(:path)
    "#"
  end

  def item_title(item)
    return item.title if item.respond_to?(:title)
    item.to_s
  end

  def item_image(item)
    return image_tag(item.hero_image.variant(resize_to_fill: [ 24, 24 ]), class: "w-6 h-6 rounded") if item.respond_to?(:hero_image) && item.hero_image.attached?
    nil
  end

  def button_text_color
    button_style[:text_color] || "currentColor"
  end

  def button_background_color
    button_style[:background_color] || "transparent"
  end
end
