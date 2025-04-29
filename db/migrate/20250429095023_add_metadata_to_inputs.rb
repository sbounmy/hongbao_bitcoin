class AddMetadataToInputs < ActiveRecord::Migration[8.0]
  def change
    change_table :inputs do |t|
      t.json :metadata, null: false, default: '{}'
    end
  end
end
