ActiveAdmin.register Content::Quote, as: "Quote" do
  permit_params :slug, :published_at, :parent_id, :position,
                :avatar,
                metadata: {}

  # Customize index page
  index do
    selectable_column
    id_column
    column :author
    column :quote do |quote|
      truncate(quote.quote, length: 100)
    end
    column :category
    column :products do |quote|
      link_to quote.products.count, admin_products_path(q: { parent_id_eq: quote.id })
    end
    column :published_at
    column :impressions_count
    actions
  end

  # Customize form
  form do |f|
    f.inputs "Quote Details" do
      f.input :slug
      f.input :published_at, as: :datetime_picker
      f.input :position
    end

    f.inputs "Images" do
      f.input :avatar, as: :file, hint: f.object.avatar.attached? ? image_tag(f.object.avatar, style: "max-width: 200px;") : "Author avatar image"
    end

    f.inputs "Quote Content (JSON)", for: :metadata do |df|
      f.input :metadata, as: :text,
              input_html: {
                rows: 20,
                value: JSON.pretty_generate(f.object.metadata || {}),
                class: "json-editor"
              },
              hint: "Edit as JSON. Fields: author, quote, year, category, gradient, icon, source, full_quote (images are now handled via file uploads)"
    end

    f.actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :slug
      row :author
      row :quote
      row :full_quote
      row :year
      row :source
      row :category
      row :gradient do |quote|
        div class: "p-4 rounded text-white bg-gradient-to-br #{quote.gradient}" do
          quote.gradient
        end
      end
      row :icon do |quote|
        span(quote.icon, class: "text-4xl")
      end
      row :avatar do |quote|
        if quote.avatar.attached?
          image_tag quote.avatar, class: "w-20 h-20 rounded-full"
        end
      end
      row :published_at
      row :impressions_count
      row :created_at
      row :updated_at
    end

    panel "Related Products (#{quote.products.count})" do
      table_for quote.products.ordered do
        column :position
        column :title
        column :shop
        column :price do |product|
          "$#{product.price}"
        end
        column :featured do |product|
          status_tag product.featured?
        end
        column :actions do |product|
          span do
            link_to "View", admin_product_path(product), class: "member_link"
          end
          span do
            link_to "Edit", edit_admin_product_path(product), class: "member_link"
          end
        end
      end

      div class: "action_items" do
        link_to "Add Product", new_admin_product_path(product: { parent_id: quote.id }),
                class: "button"
      end
    end
  end

  # Filters
  filter :slug
  filter :metadata_contains, as: :string, label: "Author"
  filter :published_at
  filter :impressions_count

  # Controller actions
  controller do
    def update
      # Parse JSON metadata if it's a string
      if params[:quote][:metadata].is_a?(String)
        begin
          params[:quote][:metadata] = JSON.parse(params[:quote][:metadata])
        rescue JSON::ParserError
          flash[:error] = "Invalid JSON in metadata field"
          redirect_back(fallback_location: admin_quotes_path) and return
        end
      end
      super
    end

    def create
      # Parse JSON metadata if it's a string
      if params[:quote][:metadata].is_a?(String)
        begin
          params[:quote][:metadata] = JSON.parse(params[:quote][:metadata])
        rescue JSON::ParserError
          flash[:error] = "Invalid JSON in metadata field"
          redirect_back(fallback_location: admin_quotes_path) and return
        end
      end
      super
    end
  end
end
