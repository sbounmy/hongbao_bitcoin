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
                ["#{ov.option_type.presentation}: #{ov.presentation}", ov.id]
              }
    end

    f.inputs "Images" do
      f.has_many :images_attachments, allow_destroy: true do |a|
        if a.object.persisted? && a.object.blob
          a.input :_destroy, as: :boolean, label: "Remove #{a.object.filename}"
          a.template.content_tag(:li) do
            a.template.image_tag(a.template.url_for(a.object), style: "max-width: 200px;")
          end
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

    active_admin_comments
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