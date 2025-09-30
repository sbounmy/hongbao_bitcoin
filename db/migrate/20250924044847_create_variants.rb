class CreateVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku, null: false
      t.decimal :price, precision: 10, scale: 2
      t.string :stripe_price_id
      t.json :option_value_ids, default: []
      t.boolean :is_master, default: false
      t.integer :position, default: 0

      t.timestamps
    end
    add_index :variants, :sku, unique: true
    add_index :variants, :stripe_price_id
    add_index :variants, :is_master
    add_index :variants, :position
  end
end
