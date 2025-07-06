class AddPositionToInputs < ActiveRecord::Migration[8.0]
  def change
    add_column :inputs, :position, :integer, default: 0
    add_index :inputs, :position
  end
end
