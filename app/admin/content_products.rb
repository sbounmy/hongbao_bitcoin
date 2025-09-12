ActiveAdmin.register Content::Product, as: "Product" do
  menu parent: "Contents", priority: 2

  permit_params :slug, :published_at, :parent_id, :position,
                :image,
                metadata: {}

  # Customize index page
  index do
    selectable_column
    id_column
    column :title
    column :shop
    column :price do |product|
      "$#{product.price}"
    end
    column :parent do |product|
      if product.parent
        link_to product.parent.author || product.parent.name,
                admin_quote_path(product.parent)
      end
    end
    column :featured do |product|
      status_tag product.featured?
    end
    column :position
    actions
  end

  # Customize form
  form do |f|
    f.inputs "Product Details" do
      f.input :parent_id, as: :select,
              collection: Content::Quote.all.map { |q| [ q.author + " - " + q.quote.truncate(50), q.id ] },
              include_blank: false,
              label: "Parent Quote"
      f.input :slug, hint: "Auto-generated if left blank"
      f.input :published_at, as: :datetime_picker
      f.input :position, hint: "Order within parent quote"
    end

    f.inputs "Product Image" do
      f.input :image, as: :file, hint: f.object.image.attached? ? image_tag(f.object.image, style: "max-width: 200px;") : "Product image"
    end

    f.inputs "Product Data" do
      f.input :metadata, as: :text,
              input_html: {
                rows: 20,
                value: JSON.pretty_generate(f.object.metadata || default_product_data),
                class: "json-editor"
              },
              hint: "Edit as JSON. Required fields: title, shop, price, url. Optional: featured, commission, affiliate_url, description, icon (images are now handled via file uploads)"
    end

    f.actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :slug
      row :parent do |product|
        if product.parent
          link_to product.parent.respond_to?(:author) ? product.parent.author : product.parent.name,
                  admin_quote_path(product.parent)
        end
      end
      row :title
      row :shop do |product|
        status_tag product.shop, class: product.internal? ? "yes" : "no"
      end
      row :price do |product|
        "$#{product.price} #{product.currency}"
      end
      row :image do |product|
        if product.image.attached?
          image_tag product.image, class: "max-w-xs"
        end
      end
      row :product_url do |product|
        link_to product.product_url, product.product_url, target: "_blank" if product.product_url
      end
      row :affiliate_url do |product|
        link_to product.affiliate_url, product.affiliate_url, target: "_blank" if product.affiliate_url
      end
      row :commission do |product|
        "#{product.commission}%"
      end
      row :featured do |product|
        status_tag product.featured?
      end
      row :position
      row :published_at
      row :created_at
      row :updated_at
    end

    panel "Raw Data" do
      pre do
        JSON.pretty_generate(product.metadata)
      end
    end
  end

  # Filters
  filter :parent, collection: -> { Content::Quote.all.map { |q| [ q.author, q.id ] } }
  filter :slug
  filter :position
  filter :published_at

  # Controller actions
  controller do
    def default_product_data
      {
        "title" => "",
        "shop" => "Hong₿ao",
        "price" => 0,
        "currency" => "USD",
        "url" => "",
        "affiliate_url" => "",
        "featured" => false,
        "commission" => 0,
        "description" => ""
      }
    end

    helper_method :default_product_data

    def update
      # Parse JSON metadata if it's a string
      if params[:product][:metadata].is_a?(String)
        begin
          params[:product][:metadata] = JSON.parse(params[:product][:metadata])
        rescue JSON::ParserError
          flash[:error] = "Invalid JSON in metadata field"
          redirect_back(fallback_location: admin_products_path) and return
        end
      end
      super
    end

    def create
      # Parse JSON metadata if it's a string
      if params[:product][:metadata].is_a?(String)
        begin
          params[:product][:metadata] = JSON.parse(params[:product][:metadata])
        rescue JSON::ParserError
          flash[:error] = "Invalid JSON in metadata field"
          redirect_back(fallback_location: admin_products_path) and return
        end
      end
      super
    end

    def new
      super do |format|
        if params[:product] && params[:product][:parent_id]
          @product.parent_id = params[:product][:parent_id]
        end
      end
    end
  end

  # Batch actions
  batch_action :mark_as_featured do |ids|
    batch_action_collection.find(ids).each do |product|
      product.featured = true
      product.save
    end
    redirect_to collection_path, alert: "Products marked as featured."
  end

  batch_action :unmark_as_featured do |ids|
    batch_action_collection.find(ids).each do |product|
      product.featured = false
      product.save
    end
    redirect_to collection_path, alert: "Products unmarked as featured."
  end
end
