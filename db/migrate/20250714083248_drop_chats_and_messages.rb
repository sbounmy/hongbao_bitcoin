class DropChatsAndMessages < ActiveRecord::Migration[8.0]
  def change
    remove_column :papers, :message_id, :bigint
    remove_column :papers, :parent_id, :bigint
    drop_table :messages
    drop_table :chats
  end
end
