class AddStripeAndStatusToHongBaos < ActiveRecord::Migration[8.0]
  def change
    add_column :hong_baos, :stripe_session_id, :string
    add_column :hong_baos, :status, :integer, default: 0
    add_index :hong_baos, :stripe_session_id
  end
end
