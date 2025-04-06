class CreateTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tokens_sum, :integer, default: 0, null: false

    create_table :tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :description
      t.json :metadata, null: false, default: '{}'

      t.timestamps
    end

    add_index :tokens, :created_at
  end
end
