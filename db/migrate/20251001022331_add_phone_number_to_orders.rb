class AddPhoneNumberToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :phone_number, :string
  end
end
