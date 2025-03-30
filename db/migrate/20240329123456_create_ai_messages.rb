class CreateAiMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_messages do |t|
      t.string :name, null: false
      t.text :description
      t.text :text, null: false
      t.string :type # For STI
      t.timestamps
    end

    add_index :ai_messages, :type
  end
end
