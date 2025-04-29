ActiveAdmin.register Input::Theme, as: "Theme" do
  permit_params :name, :image, :prompt, :ui_name, Input::Theme::UI_PROPERTIES.map { |p| "ui_#{p}" }

  remove_filter :hero_image_attachment, :hero_image_blob, :image_attachment, :image_blob, :input_items, :bundles, :prompt, :slug


  form do |f|
    # ONLY FOR INPUT::THEME TO BE MOVED TO admin/input_themes :todo:
    f.inputs "Theme Details" do
      f.input :name
      f.input :prompt
      f.input :image, as: :file
      f.input :hero_image, as: :file
      f.input :ui_name, as: :select, collection: [
        "light", "dark", "cupcake", "bumblebee", "emerald", "corporate",
        "synthwave", "retro", "cyberpunk", "valentine", "halloween", "garden",
        "forest", "aqua", "lofi", "pastel", "fantasy", "wireframe", "black",
        "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
        "night", "coffee", "winter", "dim", "nord", "sunset"
      ]
    end

    # Define hints based on property descriptions
    property_hints = {
      "color_base_100" => "Base color of page, used for blank backgrounds",
      "color_base_200" => "Base color, darker shade",
      "color_base_300" => "Base color, even more darker shade",
      "color_base_content" => "Foreground content color to use on base color",
      "color_primary" => "Primary brand color",
      "color_primary_content" => "Foreground content color to use on primary color",
      "color_secondary" => "Secondary brand color",
      "color_secondary_content" => "Foreground content color to use on secondary color",
      "color_accent" => "Accent brand color",
      "color_accent_content" => "Foreground content color to use on accent color",
      "color_neutral" => "Neutral dark color",
      "color_neutral_content" => "Foreground content color to use on neutral color",
      "color_info" => "Info color",
      "color_info_content" => "Foreground content color to use on info color",
      "color_success" => "Success color",
      "color_success_content" => "Foreground content color to use on success color",
      "color_warning" => "Warning color",
      "color_warning_content" => "Foreground content color to use on warning color",
      "color_error" => "Error color",
      "color_error_content" => "Foreground content color to use on error color",
      "radius_selector" => "Border radius for selectors like checkbox, toggle, badge, etc",
      "radius_field" => "Border radius for fields like input, select, tab, etc",
      "radius_box" => "Border radius for boxes like card, modal, alert, etc",
      "size_selector" => "Base scale size for selectors like checkbox, toggle, badge, etc",
      "size_field" => "Base scale size for fields like input, select, tab, etc",
      "border" => "Border width of all components",
      "depth" => "(binary) Adds a depth effect for relevant components",
      "noise" => "(binary) Adds a background noise effect for relevant components"
    }

    # ONLY FOR INPUT::THEME TO BE MOVED TO admin/input_themes :todo:
    f.inputs "Theme Colors" do
      para do
        text_node "Refer to the "
        a "DaisyUI documentation", href: "https://daisyui.com/docs/themes/#how-to-add-a-new-custom-theme", target: "_blank", rel: "noopener noreferrer"
        text_node " for details on theme properties and their effects."
      end

      # Use underscored properties for iteration and hint lookup
      Input::Theme::UI_PROPERTIES.each do |prop|
        if prop.include?("color")
          # Use color picker for color properties
          input_id = "ai_theme_ui_#{prop}" # Consistent ID for input and JS target
          button_html = content_tag(
            :button,
            "✕",
            type: "button",
            onclick: "document.getElementById('#{input_id}').value = ''; return false;",
            title: "Reset color",
            style: "margin-left: 8px; vertical-align: middle; cursor: pointer; padding: 1px 5px; line-height: 1;"
            # Optionally add a class like 'button button-outline button-small'
          )
          original_hint = property_hints[prop] || ""
          combined_hint = "#{original_hint} #{button_html}".html_safe

          f.input "ui_#{prop}", # Use symbol key for formtastic
                  label: prop.humanize,
                  hint: combined_hint, # Use the combined hint with the button
                  as: :string,
                  input_html: {
                    type: "color",
                    value: f.object.ui[prop],
                    id: input_id # Ensure the ID is set for the JS
                  }
        else
          # Regular input for non-color properties
          f.input "ui_#{prop}", # Use symbol key for formtastic
                  label: prop.humanize,
                  hint: property_hints[prop],
                  input_html: {
                    value: f.object.ui[prop]
                  }
        end
      end
    end
  f.actions
  end
end
