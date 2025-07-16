ActiveAdmin.register Input::Style, as: "Style" do
  menu parent: "Inputs", priority: 2
  
  permit_params :name, :image, :prompt, :position, :ui_name, Input::Theme::UI_PROPERTIES.map { |p| "ui_#{p}" }

  remove_filter :image_attachment, :image_blob, :input_items, :bundles, :prompt, :slug

  config.sort_order = "position_asc"

  index do
    selectable_column
    id_column
    column :position
    column :name
    column :prompt
    column :image do |style|
      if style.image.attached?
        image_tag style.image, style: "width: 100px;"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :position
      row :name
      row :prompt
      row :image do |style|
        if style.image.attached?
          image_tag style.image, style: "width: 500px;"
        end
      end
    end
  end
  form do |f|
    f.inputs do
      f.input :position, hint: "Used to order styles in the interface (lower numbers appear first)"
      f.input :name
      f.input :prompt
      f.input :image, as: :file, hint: f.object.image.attached? ? image_tag(url_for(f.object.image), width: 500) : nil
    end
    f.actions
  end
end
