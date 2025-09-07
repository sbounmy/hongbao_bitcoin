class CreateContents < ActiveRecord::Migration[8.0]
  def change
    create_table :contents do |t|
      t.string :type, null: false # For STI
      t.string :slug, null: false
      t.string :title
      t.string :h1
      t.text :meta_description
      t.json :metadata, default: {}
      t.datetime :published_at
      t.integer :impressions_count, default: 0
      t.integer :clicks_count, default: 0
      t.references :parent, null: true, foreign_key: { to_table: :contents }
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :contents, :slug, unique: true
    add_index :contents, :type
    add_index :contents, [ :type, :published_at ]
    add_index :contents, [ :parent_id, :type ]
    add_index :contents, [ :parent_id, :position ]
  end
end
