class CreatePapers < ActiveRecord::Migration[8.0]
  def change
    create_table :papers do |t|
      t.string :name
      t.integer :style, default: 0
      t.boolean :active, default: true
      t.integer :position
      t.timestamps
    end

    add_reference :hong_baos, :paper, foreign_key: true
  end
end
