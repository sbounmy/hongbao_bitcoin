class RenameEmailAddressToEmailInUsers < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :email_address, :email
  end
end
