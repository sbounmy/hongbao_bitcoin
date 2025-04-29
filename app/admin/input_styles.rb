ActiveAdmin.register Input::Style, as: "Style" do
  permit_params :name, :image, :prompt, :ui_name, Input::Theme::UI_PROPERTIES.map { |p| "ui_#{p}" }

  remove_filter :image_attachment, :image_blob, :input_items, :bundles, :prompt, :slug
  form do |f|
    f.inputs do
      f.input :name
      f.input :prompt
      f.input :image, as: :file
    end
    f.actions
  end
end
