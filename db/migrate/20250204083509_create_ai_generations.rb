class CreateAiGenerations < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_generations do |t|
      t.string :prompt, null: false
      t.string :generation_id, null: false
      t.string :status, null: false
      t.text :image_urls

      t.timestamps
    end

    add_index :ai_generations, :generation_id, unique: true
  end
end
