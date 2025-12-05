ActiveAdmin.register OptionValue do
  menu parent: "E-Commerce", priority: 4

  permit_params :option_type_id, :name, :presentation, :color, :position, :envelopes_count, :tokens_count

  index do
    selectable_column
    id_column
    column :option_type
    column :name
    column :presentation
    column :color do |value|
      if value.color.present?
        div style: "display: flex; align-items: center; gap: 8px;" do
          span style: "display: inline-block; width: 30px; height: 30px; background-color: #{value.color}; border: 1px solid #ddd; border-radius: 50%;"
          span value.color
        end
      else
        span "-", style: "color: #999;"
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

      # Only show color input for color option types
      if f.object.option_type&.name == "color" || f.object.new_record?
        f.input :color,
                hint: "Select the color for this option value",
                input_html: {
                  type: "color",
                  value: f.object.color || "#000000",
                  style: "width: 100px; height: 40px; cursor: pointer;"
                }
      end

      f.input :position
    end

    # Only show envelopes/tokens count for size option types
    if f.object.option_type&.name == "size" || f.object.new_record?
      f.inputs "Pack Contents (Size Options Only)" do
        f.input :envelopes_count, as: :number, hint: "Number of envelopes in this size pack",
                input_html: { value: f.object.envelopes_count }
        f.input :tokens_count, as: :number, hint: "Number of AI credits included",
                input_html: { value: f.object.tokens_count }
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :option_type
      row :name
      row :presentation
      row :color do |value|
        if value.color.present?
          div style: "display: flex; align-items: center; gap: 12px;" do
            span style: "display: inline-block; width: 60px; height: 60px; background-color: #{value.color}; border: 2px solid #ddd; border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"
            div do
              strong value.color
              br
              span value.presentation, style: "color: #666; font-size: 12px;"
            end
          end
        else
          span "No color set", style: "color: #999;"
        end
      end
      row :position
      row :envelopes_count do |value|
        value.envelopes_count || "-"
      end
      row :tokens_count do |value|
        value.tokens_count || "-"
      end
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

  batch_action :set_color, form: -> {
    {
      color: {
        input: :color,
        label: "Select Color",
        required: true,
        input_html: { value: "#000000" }
      }
    }
  } do |ids, inputs|
    batch_action_collection.find(ids).each do |option_value|
      option_value.update(color: inputs[:color])
    end
    redirect_to collection_path, notice: "Colors updated for #{ids.size} option values!"
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
