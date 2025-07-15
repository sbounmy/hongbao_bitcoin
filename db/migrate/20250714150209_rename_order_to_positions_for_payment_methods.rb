class RenameOrderToPositionsForPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    rename_column :payment_methods, :order, :position
  end
end
