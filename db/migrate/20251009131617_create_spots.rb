class CreateSpots < ActiveRecord::Migration[8.0]
  def change
    create_table :spots do |t|
      t.date :date, null: false
      t.json :prices, default: {}
      t.datetime :imported_at
      t.timestamps
    end

    add_index :spots, :date, unique: true
  end
end
