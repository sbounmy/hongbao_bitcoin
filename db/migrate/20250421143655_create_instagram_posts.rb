class CreateInstagramPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :instagram_posts do |t|
      t.string :media_url, null: false
      t.string :permalink, null: false
      t.text :caption
      t.datetime :published_at, null: false
      t.string :media_type # e.g., IMAGE, VIDEO, CAROUSEL_ALBUM
      t.string :instagram_id # Optional: Store original ID if needed
      t.integer :position, default: 0 # For manual sorting
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :instagram_posts, :active
    add_index :instagram_posts, :position
    add_index :instagram_posts, :published_at
    add_index :instagram_posts, :instagram_id, unique: true # If you want to prevent duplicates based on original ID
  end
end
