ActiveAdmin.register Product, as: "ShopProduct" do
  menu label: "Products", parent: "E-Commerce", priority: 1

  permit_params :name, :slug, :description, :meta_description, :stripe_product_id,
                :position, :published_at, :master_variant_id,
                metadata: [:envelopes_count, :tokens_count],
                option_type_ids: []

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column "Envelopes" do |product|
      product.envelopes_count
    end
    column "Tokens" do |product|
      product.tokens_count
    end
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

    f.inputs "Metadata" do
      f.input :envelopes_count, input_html: { value: f.object.envelopes_count || 0 }
      f.input :tokens_count, input_html: { value: f.object.tokens_count || 0 }
    end

    f.inputs "Option Types" do
      f.input :option_type_ids, as: :check_boxes, collection: OptionType.all.map { |ot| [ot.presentation, ot.id] }
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
      row :envelopes_count
      row :tokens_count
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
      table_for product.variants do
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

    active_admin_comments
  end

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end

    def update
      if params[:product][:envelopes_count] || params[:product][:tokens_count]
        resource.metadata ||= {}
        resource.metadata["envelopes_count"] = params[:product][:envelopes_count].to_i if params[:product][:envelopes_count]
        resource.metadata["tokens_count"] = params[:product][:tokens_count].to_i if params[:product][:tokens_count]
        params[:product].delete(:envelopes_count)
        params[:product].delete(:tokens_count)
      end
      super
    end

    def create
      if params[:product][:envelopes_count] || params[:product][:tokens_count]
        params[:product][:metadata] ||= {}
        params[:product][:metadata][:envelopes_count] = params[:product][:envelopes_count].to_i if params[:product][:envelopes_count]
        params[:product][:metadata][:tokens_count] = params[:product][:tokens_count].to_i if params[:product][:tokens_count]
        params[:product].delete(:envelopes_count)
        params[:product].delete(:tokens_count)
      end
      super
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
    link_to "Duplicate", duplicate_admin_shop_product_path(shop_product), method: :post
  end
end