class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.string :slug
      t.integer :position
      t.json :metadata, default: {}
      t.json :categories, default: []

      t.timestamps
    end

    add_index :tags, :slug, unique: true
  end
end
