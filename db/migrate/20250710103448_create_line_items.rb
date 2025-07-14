class CreateLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :line_items do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :price, null: false
      t.string :stripe_price_id
      t.json :metadata, default: {}

      t.timestamps
    end
  end
end
