ActiveAdmin.register Variant do
  menu parent: "E-Commerce", priority: 2

  permit_params :product_id, :sku, :price, :stripe_price_id, :is_master,
                :position, :metadata, option_value_ids: [], images: []

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

    if f.object.persisted? && f.object.images.any?
      f.inputs "Current Images" do
        li class: "string input optional stringish" do
          label "Attached Images", for: "variant_images_display", class: "label"
          div style: "margin-left: 20%; padding: 10px 0;" do
            f.object.images.each do |image|
              span style: "display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; text-align: center; vertical-align: top;" do
                img src: url_for(image), style: "max-width: 200px; max-height: 200px; display: block; margin-bottom: 10px;"
                text_node image.filename.to_s
                br
                a "Delete",
                  href: admin_attachment_path(image),
                  data: {
                    method: :delete,
                    confirm: "Are you sure you want to delete this image?",
                    turbo: false
                  },
                  class: "button",
                  style: "background: #dc2626; color: white; padding: 5px 15px; text-decoration: none; border-radius: 3px; display: inline-block; margin-top: 5px;"
              end
            end
          end
        end
      end
    end

    f.inputs "Add New Images" do
      f.input :images, as: :file, input_html: { multiple: true }, label: false, hint: "Select multiple images to upload"
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

  batch_action :update_position do |ids|
    batch_action_collection.find(ids).each_with_index do |variant, index|
      variant.update(position: index)
    end
    redirect_to collection_path, notice: "Positions updated!"
  end
end
