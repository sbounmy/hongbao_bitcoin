class AddMnemonicSeedToHongBaos < ActiveRecord::Migration[8.0]
  def change
    add_column :hong_baos, :mnemonic, :text
    add_column :hong_baos, :seed, :text
    add_column :hong_baos, :entropy, :text

    # Add indexes if you plan to query by these fields
    add_index :hong_baos, :seed, unique: true
  end
end
