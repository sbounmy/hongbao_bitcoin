class AddCachingFieldsToSavedHongBaos < ActiveRecord::Migration[8.0]
  def change
    # Rename initial_usd to initial_spot_usd for clarity
    rename_column :saved_hong_baos, :initial_usd, :initial_spot_usd

    # Add caching fields to avoid constant API calls
    add_column :saved_hong_baos, :cached_satoshis, :integer, limit: 8 # bigint for satoshis
    add_column :saved_hong_baos, :cached_spot_usd, :decimal, precision: 10, scale: 2
    add_column :saved_hong_baos, :last_fetched_at, :datetime
  end
end
