ActiveAdmin.register OptionValue do
  menu parent: "E-Commerce", priority: 4

  permit_params :option_type_id, :name, :presentation, :hex_color, :position

  index do
    selectable_column
    id_column
    column :option_type
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
    column "Used by Variants" do |value|
      Variant.with_option_value(value.id).count
    end
    actions
  end

  filter :option_type
  filter :name
  filter :presentation
  filter :created_at

  form do |f|
    f.inputs "Option Value Details" do
      f.input :option_type, hint: "The option type this value belongs to"
      f.input :name, hint: "Internal name (e.g., 'red', 'mini')"
      f.input :presentation, hint: "Display name (e.g., 'Red', 'Mini Pack')"
      f.input :hex_color, hint: "For color values, provide hex code (e.g., #FF0000)",
              input_html: { type: "color", value: f.object.hex_color || "#000000" }
      f.input :position
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :option_type
      row :name
      row :presentation
      row :hex_color do |value|
        if value.hex_color.present?
          div do
            span style: "background-color: #{value.hex_color}; display: inline-block; width: 100px; padding: 10px; color: white; text-align: center; border-radius: 3px;" do
              value.hex_color
            end
          end
        end
      end
      row :position
      row :created_at
      row :updated_at
    end

    panel "Variants Using This Option Value" do
      variants = Variant.with_option_value(option_value.id)
      if variants.any?
        table_for variants do
          column :product do |variant|
            link_to variant.product.name, admin_shop_product_path(variant.product)
          end
          column :sku
          column :price do |variant|
            number_to_currency(variant.price, unit: "€")
          end
          column :is_master
          column do |variant|
            link_to "View", admin_variant_path(variant), class: "member_link"
          end
        end
      else
        para "No variants are using this option value"
      end
    end

    active_admin_comments
  end

  controller do
    def scoped_collection
      super.includes(:option_type)
    end

    def new
      @option_value = OptionValue.new
      @option_value.option_type_id = params[:option_value][:option_type_id] if params[:option_value]
      @option_value
    end
  end

  batch_action :reorder do |ids|
    batch_action_collection.find(ids).each_with_index do |option_value, index|
      option_value.update(position: index)
    end
    redirect_to collection_path, notice: "Option values reordered!"
  end

  member_action :move_up, method: :post do
    resource.move_higher
    redirect_to admin_option_values_path, notice: "Option value moved up"
  end

  member_action :move_down, method: :post do
    resource.move_lower
    redirect_to admin_option_values_path, notice: "Option value moved down"
  end

  # Custom collection action to manage values for a specific option type
  collection_action :manage, method: :get do
    @option_type = OptionType.find(params[:option_type_id])
    @option_values = @option_type.option_values.order(:position)
    render partial: "admin/option_values/manage", locals: { option_type: @option_type, option_values: @option_values }
  end
end