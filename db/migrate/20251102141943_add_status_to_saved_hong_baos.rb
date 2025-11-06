class AddStatusToSavedHongBaos < ActiveRecord::Migration[8.0]
  def change
    add_column :saved_hong_baos, :status, :string, default: "created", null: false
    add_column :saved_hong_baos, :status_changed_at, :datetime
    add_index :saved_hong_baos, :status
    add_index :saved_hong_baos, :status_changed_at
  end
end
