class RemoveIntTokensFromMessages < ActiveRecord::Migration[8.0]
  def change
    remove_column :messages, :input_tokens
    remove_column :messages, :output_tokens
  end
end
