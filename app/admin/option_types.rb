ActiveAdmin.register OptionType do
  menu parent: "E-Commerce", priority: 3

  permit_params :name, :presentation, :position

  index do
    selectable_column
    id_column
    column :name
    column :presentation
    column :position
    column "Option Values" do |option_type|
      option_type.option_values.count
    end
    actions
  end

  filter :name
  filter :presentation
  filter :created_at

  form do |f|
    f.inputs "Option Type Details" do
      f.input :name, hint: "Internal name (e.g., 'color', 'size')"
      f.input :presentation, hint: "Display name (e.g., 'Color', 'Size')"
      f.input :position
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :presentation
      row :position
      row :created_at
      row :updated_at
    end

    panel "Option Values" do
      table_for option_type.option_values.order(:position) do
        column :id
        column :name
        column :presentation
        column :hex_color do |value|
          if value.hex_color.present?
            span style: "background-color: #{value.hex_color}; padding: 2px 10px; color: white; border-radius: 3px;" do
              value.hex_color
            end
          end
        end
        column :position
        column do |value|
          link_to "Edit", edit_admin_option_value_path(value), class: "member_link"
        end
      end
      div do
        link_to "Add Option Value", new_admin_option_value_path(option_value: { option_type_id: option_type.id }),
                class: "button"
      end
    end

    panel "Products Using This Option Type" do
      products = Product.with_option_type(option_type.id)
      if products.any?
        table_for products do
          column :name do |product|
            link_to product.name, admin_shop_product_path(product)
          end
          column :slug
          column "Variants" do |product|
            product.variants.count
          end
        end
      else
        para "No products are using this option type"
      end
    end

    active_admin_comments
  end

  batch_action :reorder do |ids|
    batch_action_collection.find(ids).each_with_index do |option_type, index|
      option_type.update(position: index)
    end
    redirect_to collection_path, notice: "Option types reordered!"
  end

  member_action :move_up, method: :post do
    resource.move_higher
    redirect_to admin_option_types_path, notice: "Option type moved up"
  end

  member_action :move_down, method: :post do
    resource.move_lower
    redirect_to admin_option_types_path, notice: "Option type moved down"
  end
end