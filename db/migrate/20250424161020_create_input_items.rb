class CreateInputItems < ActiveRecord::Migration[8.0]
  def change
    create_table :input_items do |t|
      t.references :input, null: false, foreign_key: true
      t.references :bundle, null: false, foreign_key: true
      t.string :prompt
      t.timestamps
    end
  end
end
