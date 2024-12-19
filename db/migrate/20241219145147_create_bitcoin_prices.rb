class CreateBitcoinPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :bitcoin_prices do |t|
      t.date :date, null: false
      t.decimal :price, precision: 15, scale: 2, null: false
      t.string :currency, null: false

      t.timestamps

      t.index [ :date, :currency ], unique: true
    end
  end
end
