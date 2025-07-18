ActiveAdmin.register Order do
  permit_params :user_id, :payment_provider, :total_amount, :currency, :external_id, :state,
                :shipping_name, :shipping_address_line1, :shipping_address_line2,
                :shipping_city, :shipping_state, :shipping_postal_code, :shipping_country

  scope :all, default: true
  scope :pending
  scope :processing
  scope :completed
  scope :failed

  filter :state, as: :select, collection: Order.aasm.states.map(&:name)
  filter :payment_provider, as: :select, collection: Order.payment_providers.keys
  filter :user_email, as: :string
  filter :external_id
  filter :total_amount
  filter :currency
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :external_id do |order|
      link_to order.external_id, admin_order_path(order)
    end
    column :user do |order|
      order.user&.email || content_tag(:span, "Guest", class: "text-gray-500")
    end
    column :payment_provider do |order|
      render Admin::Orders::ProviderBadgeComponent.new(provider: order.payment_provider)
    end
    column :state do |order|
      render Admin::Orders::StatusBadgeComponent.new(status: order.state)
    end
    column :total_amount do |order|
      number_to_currency(order.total_amount, unit: order.currency.upcase + " ")
    end
    column :line_items do |order|
      order.line_items.count
    end
    column :created_at
    column "Provider Dashboard" do |order|
      if url = order.payment_provider_dashboard_url
        link_to "View →", url, target: "_blank", class: "btn btn-sm"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :external_id
      row :user do |order|
        if order.user
          link_to order.user.email, admin_user_path(order.user)
        else
          content_tag(:span, "Guest", class: "text-gray-500")
        end
      end
      row :payment_provider do |order|
        render Admin::Orders::ProviderBadgeComponent.new(provider: order.payment_provider)
      end
      row :state do |order|
        render Admin::Orders::StatusBadgeComponent.new(status: order.state)
      end
      row :total_amount do |order|
        number_to_currency(order.total_amount, unit: order.currency.upcase + " ")
      end
      row :currency
      row :created_at
      row :updated_at
    end

    panel "Shipping Information" do
      attributes_table_for order do
        row :shipping_name
        row :shipping_address_line1
        row :shipping_address_line2
        row :shipping_city
        row :shipping_state
        row :shipping_postal_code
        row :shipping_country
      end
    end if order.shipping_name.present?

    panel "Line Items" do
      table_for order.line_items do
        column :id
        column :quantity
        column :price do |line_item|
          number_to_currency(line_item.price, unit: order.currency.upcase + " ")
        end
        column :total_price do |line_item|
          number_to_currency(order.total_amount, unit: order.currency.upcase + " ")
        end
        column :metadata do |line_item|
          line_item.metadata if line_item.metadata.present?
        end
        column :created_at
      end
    end if order.line_items.any?

    panel "Tokens Generated" do
      table_for order.tokens do
        column :id
        column :quantity
        column :created_at
      end
    end if order.tokens.any?

    active_admin_comments
  end

  sidebar "Payment Provider", only: :show do
    div class: "sidebar_section" do
      h4 "Provider Details"
      ul do
        li do
          strong "Provider: "
          span order.payment_provider.humanize
        end
        li do
          strong "External ID: "
          code order.external_id
        end
        if url = order.payment_provider_dashboard_url
          li do
            link_to "View in #{order.payment_provider.humanize} Dashboard →",
                    url,
                    target: "_blank",
                    class: "btn btn-primary w-full mt-2"
          end
        end
      end
    end
  end

  form do |f|
    f.inputs "Order Details" do
      f.input :user, collection: User.order(:email).pluck(:email, :id)
      f.input :payment_provider, as: :select, collection: Order.payment_providers.keys
      f.input :total_amount
      f.input :currency
      f.input :external_id
      f.input :state, as: :select, collection: Order.aasm.states.map(&:name)
    end

    f.inputs "Shipping Information" do
      f.input :shipping_name
      f.input :shipping_address_line1
      f.input :shipping_address_line2
      f.input :shipping_city
      f.input :shipping_state
      f.input :shipping_postal_code
      f.input :shipping_country
    end

    f.actions
  end
end
