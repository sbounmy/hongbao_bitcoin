class CreateSavedHongBaos < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_hong_baos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address, null: false
      t.integer :initial_balance, default: 0
      t.decimal :initial_usd, precision: 10, scale: 2
      t.text :notes
      t.datetime :gifted_at

      t.timestamps
    end

    add_index :saved_hong_baos, :address
    add_index :saved_hong_baos, [:user_id, :address], unique: true
  end
end
