class AddRedirectRefToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :redirect_ref, :string
    add_index :orders, :redirect_ref
  end
end
