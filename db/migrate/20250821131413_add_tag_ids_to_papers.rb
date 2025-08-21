class AddTagIdsToPapers < ActiveRecord::Migration[8.0]
  def change
    add_column :papers, :tag_ids, :json, default: []
  end
end
