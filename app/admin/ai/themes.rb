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

    f.inputs "Theme Colors" do
      Ai::Theme::UI_PROPERTIES.each do |prop|
        if prop.include?("color")
          # Use color picker for color properties
          f.input "ui_#{prop.gsub('-', '_')}",
                  label: prop.humanize,
                  as: :string,
                  input_html: {
                    type: "color",
                    value: f.object.theme_property(prop) || "#ffffff"
                  }
        else
          # Regular input for non-color properties
          f.input "ui_#{prop.gsub('-', '_')}",
                  label: prop.humanize,
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
