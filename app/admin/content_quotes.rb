ActiveAdmin.register Content::Quote, as: "Quote" do
  menu parent: "Contents", priority: 1
  permit_params :slug, :published_at, :parent_id, :position,
                :avatar, :author, :text

  action_item :view, only: :show do
    link_to "Preview", bitcoin_content_path(resource, klass: "quotes"), target: "_blank"
  end
  # Customize index page
  index do
    selectable_column
    id_column
    column :author
    column :quote do |quote|
      truncate(quote.text, length: 100)
    end
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

    f.inputs "Quote" do
      f.input :author, as: :string, input_html: { value: f.object.author }
      f.input :text, as: :string, input_html: { value: f.object.text }
    end

    f.actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :slug
      row :author
      row :text

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
  filter :published_at
  filter :impressions_count
end
