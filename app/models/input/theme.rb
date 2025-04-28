class Input::Theme < Input
  has_one_attached :hero_image

  def ui_name
    "cyberpunk"
  end

  def theme_properties
    {
      name: name,
      slug: slug,
      hero_image: hero_image
    }
  end

  def theme_property(key)
    # theme_properties[key]
  end
end
