class CreateChats < ActiveRecord::Migration[8.0]
  def change
    create_table :chats do |t|
      t.string :model_id
      t.references :user
      t.references :bundle
      t.json :input_item_ids, default: '[]'

      t.timestamps
    end

    add_index :chats, [ :user_id, :bundle_id ]
  end
end
