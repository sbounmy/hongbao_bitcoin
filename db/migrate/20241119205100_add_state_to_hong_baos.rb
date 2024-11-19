class AddStateToHongBaos < ActiveRecord::Migration[8.0]
  def change
    add_column :hong_baos, :state, :string
  end
end
