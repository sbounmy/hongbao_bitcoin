class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, default: "pending", null: false
      t.string :payment_provider, null: false
      t.decimal :total_amount, null: false
      t.string :currency, null: false
      t.string :external_id, null: false

      t.timestamps
    end
    add_index :orders, :external_id, unique: true # to ensure duplicate webhook calls do not create duplicate orders
  end
end
