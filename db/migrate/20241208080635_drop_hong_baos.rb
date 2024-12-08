class DropHongBaos < ActiveRecord::Migration[8.0]
  def change
    drop_table :hong_baos
  end
end
