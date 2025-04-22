class DropAiGenerations < ActiveRecord::Migration[8.0]
  def up
    drop_table :ai_generations
  end

  def down
    create_table :ai_generations do |t|
      t.string :prompt, null: false
      t.text :image_urls
      t.timestamps
    end
  end
end
