class RenameSavedHongBaoColumns < ActiveRecord::Migration[8.0]
  def change
    # Rename existing columns to simpler names
    rename_column :saved_hong_baos, :initial_balance, :initial_sats
    rename_column :saved_hong_baos, :initial_spot_usd, :initial_spot
    rename_column :saved_hong_baos, :cached_satoshis, :current_sats
    rename_column :saved_hong_baos, :cached_spot_usd, :current_spot
    # last_fetched_at stays the same
  end
end
