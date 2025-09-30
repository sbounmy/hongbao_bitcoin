class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.text :meta_description
      t.string :stripe_product_id
      t.json :option_type_ids, default: []
      t.json :metadata, default: {}
      t.integer :position, default: 0
      t.datetime :published_at
      t.integer :master_variant_id

      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :stripe_product_id, unique: true
    add_index :products, :position
    add_index :products, :published_at
  end
end
