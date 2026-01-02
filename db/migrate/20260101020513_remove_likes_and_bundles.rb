class RemoveLikesAndBundles < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign keys first
    remove_foreign_key :input_items, :bundles
    remove_foreign_key :papers, :bundles
    remove_foreign_key :bundles, :users

    # Remove bundle_id from input_items
    remove_index :input_items, :bundle_id
    remove_column :input_items, :bundle_id, :integer

    # Remove likes and bundle_id from papers
    remove_index :papers, :likes_count
    remove_index :papers, :bundle_id
    remove_column :papers, :bundle_id, :integer
    remove_column :papers, :likes_count, :integer, default: 0, null: false
    remove_column :papers, :liker_ids, :json, default: []

    # Drop bundles table
    drop_table :bundles do |t|
      t.integer "user_id", null: false
      t.string "name"
      t.string "status"
      t.timestamps
      t.index [ "user_id" ], name: "index_bundles_on_user_id"
    end
  end
end
