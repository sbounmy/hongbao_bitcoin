class AddSpotIdsToSavedHongBaos < ActiveRecord::Migration[8.0]
  def change
    change_table :saved_hong_baos do |t|
      t.references :spot_buy, foreign_key: { to_table: :spots }
      t.references :spot_sell, foreign_key: { to_table: :spots }
    end
  end
end
