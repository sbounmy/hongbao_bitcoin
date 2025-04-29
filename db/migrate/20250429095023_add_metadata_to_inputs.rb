class AddMetadataToInputs < ActiveRecord::Migration[8.0]
  def change
    change_table :inputs do |t|
      t.json :metadata, null: false, default: "{}"
      t.remove :data, type: :json, default: "{}"
    end
  end
end
