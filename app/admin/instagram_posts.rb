ActiveAdmin.register InstagramPost do
  # Specify parameters which should be permitted for assignment
  permit_params :media_url, :permalink, :caption, :published_at, :media_type, :instagram_id, :position, :active

  config.comments = false

  # or consider:
  #
  # permit_params do
  #   permitted = [:media_url, :permalink, :caption, :published_at, :media_type, :instagram_id, :position, :active]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add action item for the button
  action_item :sync_instagram_posts, only: :index do
    link_to "Sync Instagram Posts", sync_posts_admin_instagram_posts_path, method: :post, data: { confirm: "This will fetch posts from the Instagram API and update the database. Continue?" }
  end

  # Add collection action to handle the button click
  collection_action :sync_posts, method: :post do
    SyncInstagramPostsJob.perform_later
    redirect_to collection_path, notice: "Instagram posts sync job enqueued. Posts will be updated shortly."
  end

  # Scopes for filtering in the index view
  scope :all
  scope :active, default: true
  scope :inactive do |scope|
    scope.where(active: false)
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :media_url
  filter :permalink
  filter :caption
  filter :published_at
  filter :media_type
  filter :instagram
  filter :position
  filter :active
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :image_preview do |post|
      raw(post.image_preview)
    end
    column :caption do |post|
      truncate(post.caption, length: 100) # Show a snippet
    end
    column :permalink do |post|
      link_to "View on Instagram", post.permalink, target: "_blank", rel: "noopener"
    end
    column :published_at
    column :position
    column :active
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :image_preview do |post|
        raw(post.image_preview)
      end
      row :media_url
      row :permalink do |post|
        link_to post.permalink, post.permalink, target: "_blank", rel: "noopener"
      end
      row :caption
      row :media_type
      row :instagram_id
      row :published_at
      row :position
      row :active
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.inputs "Instagram Post Details" do
      f.input :active
      f.input :media_url, hint: "Direct URL to the image or video file."
      f.input :permalink, hint: "URL to the post on Instagram."
      f.input :caption, as: :text, input_html: { rows: 5 }
      f.input :published_at
      f.input :media_type, hint: "e.g., IMAGE, VIDEO, CAROUSEL_ALBUM"
      f.input :instagram_id, hint: "Optional: The original ID from Instagram."
      f.input :position, hint: "Lower numbers appear first. Defaults to 0."
    end
    f.actions
  end

  # Default sorting
  config.sort_order = 'position_asc'
end
