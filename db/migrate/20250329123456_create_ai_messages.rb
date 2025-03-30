class CreateAiMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_messages do |t|
      t.string :title
      t.text :description
      t.text :text
      t.string :type # For STI
      t.timestamps
    end

    add_index :ai_messages, :type
  end
end
