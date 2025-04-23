ActiveAdmin.register Ai::Theme do
  permit_params :title, :ui_name, Ai::Theme::UI_PROPERTIES.map { |p| "ui_#{p}" }, element_ids: []

  index do
    selectable_column
    id_column
    column :title
    column :ui_name
    column :elements do |theme|
      theme.elements.map(&:title).join(", ")
    end
    column :created_at
    actions
  end

  filter :title
  filter :elements
  filter :created_at

  form do |f|
    f.semantic_errors
    f.inputs "Theme Details" do
      f.input :title
      f.input :ui_name, as: :select, collection: [
        "light", "dark", "cupcake", "bumblebee", "emerald", "corporate",
        "synthwave", "retro", "cyberpunk", "valentine", "halloween", "garden",
        "forest", "aqua", "lofi", "pastel", "fantasy", "wireframe", "black",
        "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
        "night", "coffee", "winter", "dim", "nord", "sunset"
      ]
      f.input :elements,
              as: :select,
              input_html: {
                multiple: true,
                size: 20,
                style: "min-width: 50%; height: auto;"
              },
              required: true,
              collection: Ai::Element.all.map { |e| [ "#{e.title} (#{e.status}) --- #{e.leonardo_updated_at&.strftime('%B %d, %Y')}", e.id ] }
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

    f.inputs "Theme Colors" do
      para do
        text_node "Refer to the "
        a "DaisyUI documentation", href: "https://daisyui.com/docs/themes/#how-to-add-a-new-custom-theme", target: "_blank", rel: "noopener noreferrer"
        text_node " for details on theme properties and their effects."
      end

      # Use underscored properties for iteration and hint lookup
      Ai::Theme::UI_PROPERTIES.each do |prop|
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
                    value: f.object.theme_property(prop),
                    id: input_id # Ensure the ID is set for the JS
                  }
        else
          # Regular input for non-color properties
          f.input "ui_#{prop}", # Use symbol key for formtastic
                  label: prop.humanize,
                  hint: property_hints[prop],
                  input_html: {
                    value: f.object.theme_property(prop)
                  }
        end
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :ui_name
      row :created_at
      row :updated_at

      # Display theme properties
      panel "Theme Properties" do
        table_for Ai::Theme::UI_PROPERTIES do
          column "Property" do |prop|
            prop.humanize
          end
          column "Value" do |prop|
            value = ai_theme.theme_property(prop)
            if prop.include?("color") && value.present?
              content_tag :div do
                content_tag(:div, value, style: "background-color: #{value}; display: inline-block; border: 1px solid #ddd;")
              end
            else
              value
            end
          end
        end
      end

      panel "Elements" do
        table_for ai_theme.elements do
          column :leonardo_id
          column :title
          column :weight
          column :status
        end
      end
    end
  end
end
