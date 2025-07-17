ActiveAdmin.register Input::Event, as: "Event" do
  menu parent: "Inputs", priority: 3

  permit_params :name, :image, :date, :description, :price_usd, :fixed_day, tag_ids: []

  remove_filter :image_attachment, :image_blob, :input_items, :bundles, :prompt, :slug, :metadata

  # Index page configuration
  index do
    selectable_column
    id_column
    column :name
    column :date do |event|
      event.date.strftime("%B %d, %Y") if event.date
    end
    column :price_usd do |event|
      if event.price_usd.present?
        number_to_currency(event.price_usd, unit: "$", precision: 2)
      else
        "N/A"
      end
    end
    column :age do |event|
      "#{event.age} years" if event.age > 0
    end
    column :tags do |event|
      event.tags.map { |tag| status_tag tag.name, class: "tag" }.join(" ").html_safe
    end
    column :recurring do |event|
      if event.fixed_day?
        status_tag "Fixed Date", class: "yes"
      else
        status_tag "Variable Date", class: "no"
      end
    end
    column :image do |event|
      if event.image.attached?
        image_tag event.image, style: "width: 50px; height: 50px; object-fit: cover;"
      else
        content_tag(:span, "No image", class: "empty")
      end
    end
    column :created_at
    actions
  end

  # Filters for searching
  filter :name
  filter :date
  filter :price_usd
  filter :description
  filter :tag_ids, as: :select, collection: -> { Tag.ordered.pluck(:name, :id) }, label: "Tags"
  filter :fixed_day, label: "Date Type", as: :select, collection: [ [ "Fixed Date", "true" ], [ "Variable Date", "false" ] ]
  filter :created_at

  # Show page configuration
  show do
    attributes_table do
      row :name
      row :date do |event|
        event.date.strftime("%B %d, %Y") if event.date
      end
      row :description
      row :price_usd do |event|
        if event.price_usd.present?
          number_to_currency(event.price_usd, unit: "$", precision: 2)
        else
          "N/A"
        end
      end
      row :age do |event|
        "#{event.age} years old" if event.age > 0
      end
      row :anniversary do |event|
        event.anniversary.strftime("%A, %B %d, %Y")
      end
      row :tags do |event|
        event.tags.map { |tag| status_tag tag.name, class: "tag" }.join(" ").html_safe
      end
      row :date_type do |event|
        if event.fixed_day?
          status_tag "Fixed Date - occurs on #{event.date.strftime('%B %d')} every year", class: "yes"
        else
          status_tag "Variable Date - date changes yearly", class: "no"
        end
      end
      row :image do |event|
        if event.image.attached?
          image_tag event.image, style: "max-width: 500px;"
        else
          content_tag(:span, "No image attached", class: "empty")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Papers Created for This Event" do
      table_for resource.papers.limit(10) do
        column :id do |paper|
          link_to paper.id, admin_paper_path(paper)
        end
        column :name
        column :creator do |paper|
          paper.user&.email || "Anonymous"
        end
        column :created_at
      end

      if resource.papers.count > 10
        div do
          text_node "Showing 10 of #{resource.papers.count} papers. "
          link_to "View all", admin_papers_path(q: { input_items_input_id_eq: resource.id })
        end
      elsif resource.papers.count == 0
        div do
          text_node "No papers have been created for this event yet."
        end
      end
    end
  end

  # Sidebar for additional info
  sidebar "Event Statistics", only: [ :show, :edit ] do
    attributes_table_for resource do
      row :papers_count do |event|
        event.papers.count
      end
      row :next_anniversary do |event|
        event.anniversary.strftime("%B %d, %Y")
      end
      row :days_until do |event|
        days = (event.anniversary - Date.current).to_i
        "#{days} days"
      end
    end
  end

  sidebar "Quick Actions", only: :show do
    ul do
      li link_to "View in Calendar", preview_calendar_admin_event_path(resource), target: "_blank"
      li link_to "View Public Page", input_path(resource), target: "_blank"
      li link_to "Edit Event", edit_admin_event_path(resource)
      li link_to "Delete Event", admin_event_path(resource), method: :delete, data: { confirm: "Are you sure?" }
    end
  end

  # Form for creating/editing
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Event Details" do
      f.input :name, hint: "The name of the Bitcoin event"
      f.input :date, as: :string, input_html: { type: "date", value: f.object.date&.strftime("%Y-%m-%d") }, hint: "The date when this event occurred"
      f.input :description, as: :text, input_html: { rows: 4 }, hint: "A brief description of the event's significance"
      f.input :price_usd,
              label: "Bitcoin Price (USD)",
              hint: "The price of 1 BTC in USD on this date (optional)"
      f.input :fixed_day,
              label: "Date Type",
              as: :select,
              collection: [ [ " Fixed Date (same date every year, e.g., Bitcoin Pizza Day - May 22)", true ],
                           [ " Variable Date (changes yearly, e.g., Chinese New Year)", false ] ],
              include_blank: false,
              hint: "Select whether this event occurs on the same calendar date every year"
      f.input :tag_ids,
              label: "Tags",
              as: :select,
              collection: Tag.ordered.pluck(:name, :id),
              input_html: { multiple: true, class: "select2" },
              hint: "Select tags to categorize this event"
      f.input :image, as: :file, hint: f.object.image.attached? ? image_tag(f.object.image, style: "max-width: 300px;") : "Upload an image representing this event"
    end

    f.actions
  end

  # Custom member action to view calendar
  member_action :preview_calendar, method: :get do
    @event = resource
    @date = @event.date || Date.current
    redirect_to calendar_inputs_path(date: @date)
  end

  action_item :preview_calendar, only: :show do
    link_to "View in Calendar", preview_calendar_admin_event_path(resource), target: "_blank"
  end

  # Batch actions
  batch_action :update_prices do |ids|
    batch_action_collection.find(ids).each do |event|
      # You could implement a service to fetch historical prices here
      # For now, just a placeholder
      event.update(price_usd: 0.01) if event.price_usd.blank?
    end
    redirect_to collection_path, notice: "Prices updated for selected events."
  end

  # Custom collection action for bulk import
  action_item :import, only: :index do
    link_to "Import Events", import_admin_events_path
  end

  collection_action :import, method: :get do
    # Renders the import view
  end

  collection_action :do_import, method: :post do
    if params[:file].blank?
      redirect_to import_admin_events_path, alert: "Please select a CSV file to import."
      return
    end

    require "csv"
    imported_count = 0
    error_count = 0
    errors = []

    begin
      CSV.foreach(params[:file].path, headers: true) do |row|
        event = Input::Event.new(
          name: row["name"],
          date: row["date"],
          description: row["description"],
          price_usd: row["price_usd"]
        )

        if event.save
          imported_count += 1
        else
          error_count += 1
          errors << "Row #{CSV.lineno}: #{event.errors.full_messages.join(', ')}"
        end
      end

      if error_count > 0
        flash[:error] = "Import finished with #{error_count} errors: #{errors.join('; ')}"
      else
        flash[:notice] = "Successfully imported #{imported_count} events."
      end
    rescue => e
      flash[:alert] = "Error processing CSV file: #{e.message}"
    end

    redirect_to admin_events_path
  end

  # Scopes for filtering
  scope :all, default: true
  scope :with_price do |events|
    events.where.not("metadata->>'price_usd' IS NULL AND metadata->>'price_usd' != ''")
  end
  scope :without_price do |events|
    events.where("metadata->>'price_usd' IS NULL OR metadata->>'price_usd' = ''")
  end
  scope :recent do |events|
    # SQLite compatible date comparison
    events.where("date(metadata->>'date') >= date(?)", 1.year.ago.to_date)
  end
  scope :historical do |events|
    # SQLite compatible date comparison
    events.where("date(metadata->>'date') < date(?)", 1.year.ago.to_date)
  end
end
