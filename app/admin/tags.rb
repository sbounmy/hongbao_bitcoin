ActiveAdmin.register Tag do
  menu priority: 20

  permit_params :name, :slug, :color, :icon, :position, categories: []

  # Index page
  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :color do |tag|
      if tag.color.present?
        content_tag(:span, tag.color, style: "background-color: #{tag.color}; color: white; padding: 4px 8px; border-radius: 4px;")
      end
    end
    column :icon
    column :position
    column :categories do |tag|
      tag.categories.join(", ")
    end
    column :events_count do |tag|
      Input::Event.with_any_tag_ids(tag.id).count
    end
    column :created_at
    actions
  end

  # Filters
  filter :name
  filter :slug
  filter :created_at

  # Show page
  show do
    attributes_table do
      row :name
      row :slug
      row :color do |tag|
        if tag.color.present?
          content_tag(:span, tag.color, style: "background-color: #{tag.color}; color: white; padding: 4px 8px; border-radius: 4px;")
        end
      end
      row :icon
      row :position
      row :categories do |tag|
        tag.categories.join(", ")
      end
      row :created_at
      row :updated_at
    end

    panel "Events with this Tag" do
      events = Input::Event.with_any_tag_ids(resource.id)

      if events.any?
        table_for events do
          column :id do |event|
            link_to event.id, admin_event_path(event)
          end
          column :name
          column :date
          column :fixed_day do |event|
            if event.fixed_day?
              status_tag "Fixed", class: "yes"
            else
              status_tag "Variable", class: "no"
            end
          end
        end
      else
        div do
          text_node "No events are tagged with this tag."
        end
      end
    end
  end

  # Form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Tag Details" do
      f.input :name, hint: "Display name for the tag"
      f.input :slug, hint: "URL-friendly version (auto-generated if blank)"
      f.input :color,
              as: :string,
              input_html: { type: "color", value: f.object.color || "#ff9500" },
              hint: "Color for the tag (used in calendar views)"
      f.input :icon,
              hint: "Icon name from Heroicons (e.g., 'star', 'calendar', 'globe-alt')"
      f.input :position,
              hint: "Order position (lower numbers appear first)"
      f.input :categories,
              as: :check_boxes,
              collection: Tag::CATEGORIES,
              hint: "Categories this tag belongs to"
    end

    f.actions
  end

  # Scopes
  scope :all, default: true
  scope :ordered do |tags|
    tags.ordered
  end
  scope :with_events do |tags|
    tag_ids = Input::Event.unique_tag_ids
    tags.where(id: tag_ids)
  end

  # Sort by position by default
  config.sort_order = "position_asc"
end
