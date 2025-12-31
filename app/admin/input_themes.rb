ActiveAdmin.register Input::Theme, as: "Theme" do
  menu parent: "Inputs", priority: 1

  # Use FriendlyId slug for finding records
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  permit_params :name, :image_front, :image_back, :image_hero, :image, :prompt, :slug, :spotify_path, :frame, :elements


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
            theme.elements = filtered_ai_data if filtered_ai_data.present?
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
      row :frame
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
      f.input :frame,
              as: :select,
              collection: Frame::TYPES.keys,
              include_blank: false,
              label: "Frame Type",
              hint: "Landscape: 150x75mm, Portrait: 75x150mm"
    end
    f.inputs "Visual Element Editor" do
      para "Drag and resize elements on the theme images. Positions and sizes are saved automatically into the form."
      render Admin::EditorComponent.new(form: f, input_base_name: "input_theme[elements]")
    end

    f.actions
  end
end
