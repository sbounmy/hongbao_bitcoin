class AddTagIdsToInputs < ActiveRecord::Migration[8.0]
  def change
    add_column :inputs, :tag_ids, :json, default: []
  end
end
