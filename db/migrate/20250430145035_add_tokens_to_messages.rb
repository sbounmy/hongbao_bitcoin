class AddTokensToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :tokens, :json, default: '{}'
  end
end
