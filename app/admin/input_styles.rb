ActiveAdmin.register Input::Style, as: "Style" do
  permit_params :name, :image, :prompt, :ui_name, Input::Theme::UI_PROPERTIES.map { |p| "ui_#{p}" }

  remove_filter :image_attachment, :image_blob, :input_items, :bundles, :prompt, :slug

  index do
    selectable_column
    id_column
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
      f.input :name
      f.input :prompt
      f.input :image, as: :file, hint: f.object.image.attached? ? image_tag(url_for(f.object.image), width: 500) : nil
    end
    f.actions
  end
end
