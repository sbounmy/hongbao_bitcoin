ActiveAdmin.register Variant do
  menu parent: "E-Commerce", priority: 2

  permit_params :product_id, :sku, :price, :stripe_price_id, :is_master,
                :position, :metadata, option_value_ids: []

  index do
    selectable_column
    id_column
    column :product
    column :sku
    column :price do |variant|
      number_to_currency(variant.price, unit: "€")
    end
    column :stripe_price_id
    column :is_master
    column "Option Values" do |variant|
      variant.option_values.map(&:presentation).join(", ")
    end
    column :position
    actions
  end

  filter :product
  filter :sku
  filter :stripe_price_id
  filter :is_master
  filter :price
  filter :created_at

  form do |f|
    f.inputs "Variant Details" do
      f.input :product
      f.input :sku
      f.input :price
      f.input :stripe_price_id
      f.input :is_master
      f.input :position
    end

    f.inputs "Option Values" do
      f.input :option_value_ids, as: :check_boxes,
              collection: OptionValue.includes(:option_type).map { |ov|
                [ "#{ov.option_type.presentation}: #{ov.presentation}", ov.id ]
              }
    end

    f.inputs "Images" do
      if f.object.persisted? && f.object.images.any?
        f.template.content_tag(:div, class: "attached-images") do
          f.template.safe_join(f.object.images.map do |image|
            f.template.content_tag(:div, style: "display: inline-block; margin: 10px;") do
              f.template.image_tag(f.template.url_for(image), style: "max-width: 200px;") +
              f.template.content_tag(:p, image.filename.to_s, style: "text-align: center;")
            end
          end)
        end
      end
      f.input :images, as: :file, input_html: { multiple: true }, hint: "Select multiple images to upload"
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :product
      row :sku
      row :price do |variant|
        number_to_currency(variant.price, unit: "€")
      end
      row :stripe_price_id
      row :is_master
      row "Option Values" do |variant|
        variant.option_values.map { |ov|
          "#{ov.option_type.presentation}: #{ov.presentation}"
        }.join(", ")
      end
      row :position
      row :created_at
      row :updated_at
    end

    panel "Images" do
      if variant.images.any?
        ul do
          variant.images.each do |image|
            li do
              image_tag url_for(image), style: "max-width: 300px;"
              br
              span image.filename.to_s
            end
          end
        end
      else
        para "No images attached"
      end
    end
  end

  controller do
    def update
      if params[:variant][:images].present?
        params[:variant][:images].each do |image|
          resource.images.attach(image)
        end
      end
      params[:variant].delete(:images)
      super
    end

    def create
      images = params[:variant].delete(:images)
      super do |success, failure|
        success.html do
          if images.present?
            images.each do |image|
              resource.images.attach(image)
            end
          end
          redirect_to admin_variant_path(resource)
        end
      end
    end
  end

  batch_action :update_position do |ids|
    batch_action_collection.find(ids).each_with_index do |variant, index|
      variant.update(position: index)
    end
    redirect_to collection_path, notice: "Positions updated!"
  end
end
