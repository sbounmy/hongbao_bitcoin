class CreateOptionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :option_types do |t|
      t.string :name, null: false
      t.string :presentation, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :option_types, :name, unique: true
    add_index :option_types, :position
  end
end
