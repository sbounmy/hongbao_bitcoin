class AddStateToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :state, :string
  end
end
