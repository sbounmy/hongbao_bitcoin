class CreateHongBaos < ActiveRecord::Migration[8.0]
  def change
    create_table :hong_baos do |t|
      t.decimal :amount
      t.decimal :btc_amount
      t.decimal :platform_fee
      t.decimal :gas_fee
      t.string :private_key
      t.decimal :total_cost
      t.text :personal_message

      t.timestamps
    end
  end
end
