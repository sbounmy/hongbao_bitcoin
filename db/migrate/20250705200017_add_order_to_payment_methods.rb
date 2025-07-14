class AddOrderToPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_methods, :order, :integer
  end
end
