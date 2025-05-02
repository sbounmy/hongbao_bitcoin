class AddBundleAndInputItemsToPapers < ActiveRecord::Migration[8.0]
  def change
    add_reference :papers, :bundle, foreign_key: true
    add_column :papers, :input_item_ids, :json, default: '[]'
  end
end
