class AddLikesAndViewsCountsToPapers < ActiveRecord::Migration[8.0]
  def change
    add_column :papers, :views_count, :integer, default: 0, null: false
    add_column :papers, :likes_count, :integer, default: 0, null: false
    add_column :papers, :liker_ids, :json, default: []

    add_index :papers, :views_count
    add_index :papers, :likes_count
  end
end