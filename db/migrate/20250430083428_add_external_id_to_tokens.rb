class AddExternalIdToTokens < ActiveRecord::Migration[8.0]
  def change
    change_table :tokens do |t|
      t.string :external_id
    end

    add_index :tokens, :external_id
  end
end
