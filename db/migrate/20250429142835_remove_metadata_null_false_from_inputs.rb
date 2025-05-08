class RemoveMetadataNullFalseFromInputs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :inputs, :metadata, true
  end
end
