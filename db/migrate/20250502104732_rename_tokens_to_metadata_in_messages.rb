class RenameTokensToMetadataInMessages < ActiveRecord::Migration[8.0]
  def change
    rename_column :messages, :tokens, :metadata
  end
end
