class AddOrderToTokens < ActiveRecord::Migration[8.0]
  def change
    add_reference :tokens, :order, null: true, foreign_key: true
  end
end
