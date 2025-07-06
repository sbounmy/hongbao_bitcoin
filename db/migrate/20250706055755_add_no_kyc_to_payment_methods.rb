class AddNoKycToPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_methods, :no_kyc, :boolean, default: true
  end
end
