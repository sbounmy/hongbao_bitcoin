class RemoveStripeSessionIdFromHongBaos < ActiveRecord::Migration[8.0]
  def change
    remove_column :hong_baos, :stripe_session_id
  end
end
