ActiveAdmin.register Ai::Theme do
  permit_params :title, element_ids: []

  index do
    selectable_column
    id_column
    column :title
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
    f.inputs do
      f.input :title
      f.input :elements, as: :select, input_html: { multiple: true }
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :created_at
      row :updated_at

      panel "Elements" do
        table_for ai_theme.elements do
          column :element_id
          column :title
          column :weight
        end
      end
    end
  end
end
