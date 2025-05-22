class CreateInputs < ActiveRecord::Migration[8.0]
  def change
    create_table :inputs do |t|
      t.string :name
      t.string :type
      t.string :prompt
      t.string :slug
      t.json :data
      t.timestamps
    end
  end
end
