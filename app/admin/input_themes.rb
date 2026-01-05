ActiveAdmin.register Input::Theme, as: "Theme" do
  menu parent: "Inputs", priority: 1

  # Use FriendlyId slug for finding records
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  permit_params :name, :image_front, :image_back, :image_hero, :image, :prompt, :slug, :spotify_path, :frame, :elements, :active, :position


  remove_filter :image_hero_attachment, :image_hero_blob, :image_attachment, :image_blob, :image_front_blob, :image_front_attachment, :image_back_attachment, :image_back_blob, :input_items, :prompt, :slug, :metadata

  member_action :toggle_active, method: :patch do
    resource.update!(active: !resource.active)
    redirect_to admin_themes_path, notice: "#{resource.name} is now #{resource.active? ? 'active' : 'inactive'}"
  end

  index do
    selectable_column
    id_column
    column :active do |theme|
      link_to(theme.active? ? "Active" : "Inactive",
              toggle_active_admin_theme_path(theme),
              method: :patch,
              class: theme.active? ? "text-green-600" : "text-red-600")
    end
    column :name
    column :slug
    column :position
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
      f.input :active
      f.input :position, as: :number
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
