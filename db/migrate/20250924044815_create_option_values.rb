class CreateOptionValues < ActiveRecord::Migration[8.0]
  def change
    create_table :option_values do |t|
      t.references :option_type, null: false, foreign_key: true
      t.string :name, null: false
      t.string :presentation, null: false
      t.integer :position, default: 0
      t.string :hex_color

      t.timestamps
    end

    add_index :option_values, [ :option_type_id, :name ], unique: true
    add_index :option_values, :position
  end
end
