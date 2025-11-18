ActiveAdmin.register Input::Theme, as: "Theme" do
  menu parent: "Inputs", priority: 1

  permit_params :name, :image_front, :image_back, :image_hero, :image, :prompt, :slug, :ui_name, :spotify_path,
    Input::Theme::UI_PROPERTIES.map { |p| "ui_#{p}" },
    ai: Input::Theme::AI_ELEMENT_TYPES.map { |et| { et.to_sym => Input::Theme::AI_ELEMENT_PROPERTIES.to_a } }.reduce(:merge) || {}


  remove_filter :image_hero_attachment, :image_hero_blob, :image_attachment, :image_blob, :image_front_blob, :image_front_attachment, :image_back_attachment, :image_back_blob, :input_items, :bundles, :prompt, :slug, :metadata

  # --- START: Import Functionality ---

  # Add an "Import JSON" button to the index page
  action_item :import, only: :index do
    link_to "Import JSON", action: "import_json"
  end

  # Action to display the import form
  collection_action :import_json, method: :get do
    # This will render app/views/admin/themes/import_json.html.erb
    render "admin/themes/import_json"
  end

  # Action to process the uploaded JSON file
  collection_action :process_import, method: :post do
    if params[:theme_import].blank? || params[:theme_import][:file].blank?
      redirect_to import_json_admin_themes_path, alert: "Please select a JSON file to import."
      return
    end

    file = params[:theme_import][:file]

    # Ensure it's a JSON file (basic check)
    unless file.content_type == "application/json"
      redirect_to import_json_admin_themes_path, alert: "Invalid file type. Please upload a JSON file."
      return
    end

    begin
      json_data = JSON.parse(file.read)
      imported_count = 0
      error_count = 0
      errors = []

      # Expecting an array of theme objects in the JSON
      if json_data.is_a?(Array)
        json_data.each_with_index do |theme_data, index|
          # Use slug as the unique identifier to find or initialize
          # Ensure 'slug' exists in your JSON data for each theme
          theme = Input::Theme.find_or_initialize_by(slug: theme_data["slug"])

          # Assign basic attributes (check if key exists)
          theme.name = theme_data["name"] if theme_data.key?("name")
          theme.prompt = theme_data["prompt"] if theme_data.key?("prompt")
          theme.ui_name = theme_data["ui_name"] if theme_data.key?("ui_name")
          # Add other direct attributes if needed

          # Assign UI properties from the nested 'ui' object
          if theme_data["ui"].is_a?(Hash)
            # Clear existing UI data before applying new ones? Optional.
            # theme.ui = {}
            Input::Theme::UI_PROPERTIES.each do |prop|
              # Check using the original CSS property name as likely key in JSON
              css_prop = prop.dasherize
              if theme_data["ui"].key?(css_prop)
                # Use the underscored accessor method (e.g., ui_color_primary=)
                theme.send("ui_#{prop}=", theme_data["ui"][css_prop])
              # Also check for underscored key for flexibility
              elsif theme_data["ui"].key?(prop)
                 theme.send("ui_#{prop}=", theme_data["ui"][prop])
              end
            end
          end

          # --- START: Assign AI properties from the nested 'ai' object ---
          if theme_data["ai"].is_a?(Hash)
            # Directly assign the hash to the 'ai' store.
            # Assumes the JSON structure matches the expected keys
            # (e.g., "private_key_qrcode": {"x": 0.1, "y": 0.2, ...})
            # The `store :metadata, accessors: [:ai]` handles serialization.
            # Filter the hash to only include known element types and properties for safety
            filtered_ai_data = {}
            theme_data["ai"].each do |element_type, properties|
              if Input::Theme::AI_ELEMENT_TYPES.include?(element_type) && properties.is_a?(Hash)
                filtered_properties = properties.slice(*Input::Theme::AI_ELEMENT_PROPERTIES.to_a)
                filtered_ai_data[element_type] = filtered_properties if filtered_properties.present?
              end
            end
            theme.ai = filtered_ai_data if filtered_ai_data.present?
          end
          # --- END: Assign AI properties ---

          # Attempt to save the theme
          if theme.save
            imported_count += 1
          else
            error_count += 1
            errors << "Row #{index + 1} (Slug: #{theme_data['slug'] || 'N/A'}): #{theme.errors.full_messages.join(', ')}"
          end
        end

        # Provide feedback via flash messages
        if error_count > 0
          flash[:error] = "Import finished with #{error_count} errors: <br> - #{errors.join('<br> - ')}".html_safe
        else
          flash[:notice] = "Successfully imported/updated #{imported_count} themes."
        end
      else
        flash[:alert] = "Invalid JSON format. Expected an array of theme objects."
      end

    rescue JSON::ParserError => e
      flash[:alert] = "Error parsing JSON file: #{e.message}"
    rescue => e # Catch other potential errors during processing
      flash[:alert] = "An unexpected error occurred during import: #{e.message}"
      Rails.logger.error "Theme Import Error: #{e.message}\n#{e.backtrace.join("\n")}" # Log for debugging
    end

    redirect_to admin_themes_path # Redirect back to the index page
  end

  # --- END: Import Functionality ---

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :ui_name
    column :prompt
    column :spotify_path
    column :image_hero do |theme|
      if theme.image_hero.attached?
        image_tag theme.image_hero, style: "width: 100px;"
      end
    end
    column :image do |theme|
      if theme.image.attached?
        image_tag theme.image, style: "width: 100px;"
      end
    end
    column :image_front do |theme|
      if theme.image_front.attached?
        image_tag theme.image_front, style: "width: 100px;"
      end
    end
    column :image_back do |theme|
      if theme.image_back.attached?
        image_tag theme.image_back, style: "width: 100px;"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :slug
      row :ui_name
      row :prompt
      row :image_hero do |theme|
        if theme.image_hero.attached?
          image_tag theme.image_hero, style: "width: 500px;"
        end
      end
      row :image do |theme|
        if theme.image.attached?
          image_tag theme.image, style: "width: 500px;"
        end
      end
      row :image_front do |theme|
        if theme.image_front.attached?
          image_tag theme.image_front, style: "width: 500px;"
        end
      end
      row :image_back do |theme|
        if theme.image_back.attached?
          image_tag theme.image_back, style: "width: 500px;"
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    # ONLY FOR INPUT::THEME TO BE MOVED TO admin/input_themes :todo:
    f.inputs "Theme Details" do
      f.input :name
      f.input :prompt, as: :text
      f.input :image, as: :file, hint: (f.object.image.attached? && f.object.persisted?) ? image_tag(url_for(f.object.image), width: 500) : nil
      f.input :image_hero, as: :file, hint: (f.object.image_hero.attached? && f.object.persisted?) ? image_tag(url_for(f.object.image_hero), width: 500) : nil
      f.input :image_front, as: :file, hint: (f.object.image_front.attached? && f.object.persisted?) ? image_tag(url_for(f.object.image_front), width: 500) : nil
      f.input :image_back, as: :file, hint: (f.object.image_back.attached? && f.object.persisted?) ? image_tag(url_for(f.object.image_back), width: 500) : nil
      f.input :slug
      f.input :spotify_path, as: :string, hint: "track/40KNlAhOsMqCmfnbRtQrbx from embed url"
      f.input :ui_name, as: :select, collection: [
        "light", "dark", "cupcake", "bumblebee", "emerald", "corporate",
        "synthwave", "retro", "cyberpunk", "valentine", "halloween", "garden",
        "forest", "aqua", "lofi", "pastel", "fantasy", "wireframe", "black",
        "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
        "night", "coffee", "winter", "dim", "nord", "sunset"
      ]
    end
    f.inputs "Visual Element Editor" do
      para "Drag and resize elements on the theme images. Positions and sizes are saved automatically into the form."
      render Admin::VisualEditorComponent.new(form: f, input_base_name: "input_theme[ai]")
    end

    f.inputs "Portrait Positioning" do
      para "Configure where the portrait should be positioned on the template (percentages of template dimensions)"

      f.input :portrait_resolution,
        label: "AI Portrait Resolution",
        hint: "Size for AI portrait generation (affects quality and aspect ratio)",
        as: :select,
        collection: [
          ["1024x1024 (Square)", "1024x1024"],
          ["1536x1024 (Landscape)", "1536x1024"],
          ["1024x1536 (Portrait)", "1024x1536"]
        ],
        input_html: {
          name: "input_theme[ai][portrait][resolution]"
        },
        selected: f.object.ai.dig("portrait", "resolution") || "1024x1024"

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
