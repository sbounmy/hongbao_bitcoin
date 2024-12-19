class DropBitcoinPrices < ActiveRecord::Migration[8.0]
  def change
    drop_table :bitcoin_prices, if_exists: true
  end
end
