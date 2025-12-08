ActiveAdmin.register Product, as: "ShopProduct" do
  menu label: "Products", parent: "E-Commerce", priority: 1

  permit_params :name, :slug, :description, :meta_description, :stripe_product_id,
                :position, :published_at, :master_variant_id,
                option_type_ids: [],
                images: []

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :price do |product|
      number_to_currency(product.price, unit: "€")
    end
    column :published_at
    column :position
    actions
  end

  filter :name
  filter :slug
  filter :stripe_product_id
  filter :published_at
  filter :created_at

  form do |f|
    f.inputs "Product Details" do
      f.input :name
      f.input :slug, hint: "Leave blank to auto-generate from name"
      f.input :description
      f.input :meta_description
      f.input :stripe_product_id
      f.input :position
      f.input :published_at, as: :datetime_picker
    end

    f.inputs "Option Types" do
      f.input :option_type_ids, as: :check_boxes, collection: OptionType.all.map { |ot| [ ot.presentation, ot.id ] }
    end

    if f.object.persisted? && f.object.images.any?
      f.inputs "Current Images" do
        li class: "string input optional stringish" do
          label "Attached Images", for: "product_images_display", class: "label"
          div style: "margin-left: 20%; padding: 10px 0;" do
            f.object.images.each do |image|
              span style: "display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; text-align: center; vertical-align: top;" do
                img src: url_for(image), style: "max-width: 200px; max-height: 200px; display: block; margin-bottom: 10px;"
                text_node image.filename.to_s
                br
                a "Delete",
                  href: admin_attachment_path(image),
                  data: { method: :delete, confirm: "Are you sure?", turbo: false },
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
      row :name
      row :slug
      row :description
      row :meta_description
      row :stripe_product_id
      row :price do |product|
        number_to_currency(product.price, unit: "€")
      end
      row :position
      row :published_at
      row :created_at
      row :updated_at
      row "Option Types" do |product|
        product.option_types.map(&:presentation).join(", ")
      end
    end

    panel "Variants" do
      table_for resource.variants do
        column :id
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
        column do |variant|
          link_to "View", admin_variant_path(variant), class: "member_link"
        end
      end
    end
  end

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  member_action :duplicate, method: :post do
    @product = resource
    @new_product = @product.dup
    @new_product.slug = nil # Let friendly_id generate new slug
    @new_product.name = "#{@product.name} (Copy)"
    @new_product.stripe_product_id = nil
    @new_product.published_at = nil

    if @new_product.save
      redirect_to admin_shop_product_path(@new_product), notice: "Product duplicated successfully!"
    else
      redirect_to admin_shop_products_path, alert: "Failed to duplicate product"
    end
  end

  action_item :duplicate, only: :show do
    link_to "Duplicate", duplicate_admin_shop_product_path(resource), method: :post
  end
end
