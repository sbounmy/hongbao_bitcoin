ActiveAdmin.register Ai::Theme do
  permit_params :title, leonardo_ids: []

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
    f.semantic_errors
    f.inputs do
      f.input :title
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
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :created_at
      row :updated_at

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
