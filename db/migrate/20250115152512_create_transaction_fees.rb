class CreateTransactionFees < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_fees do |t|
      t.date :date, null: false, index: { unique: true }
      t.json :priorities, null: false, default: '{}'
      t.timestamps
    end
  end
end
