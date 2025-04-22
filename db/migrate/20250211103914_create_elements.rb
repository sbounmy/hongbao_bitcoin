class CreateElements < ActiveRecord::Migration[8.0]
  def change
    create_table :elements do |t|
      t.string :element_id
      t.string :title
      t.string :weight

      t.timestamps
    end

    add_index :elements, :element_id, unique: true
  end
end
