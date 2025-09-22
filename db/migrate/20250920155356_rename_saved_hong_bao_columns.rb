class RenameSavedHongBaoColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :saved_hong_baos, :initial_balance, :initial_sats
    rename_column :saved_hong_baos, :initial_spot_usd, :initial_spot
    rename_column :saved_hong_baos, :cached_satoshis, :current_sats
    rename_column :saved_hong_baos, :cached_spot_usd, :current_spot
    change_column_default :saved_hong_baos, :initial_sats, from: 0, to: nil
  end
end
