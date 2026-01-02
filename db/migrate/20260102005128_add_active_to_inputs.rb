class AddActiveToInputs < ActiveRecord::Migration[8.0]
  def change
    change_table :inputs do |t|
      t.boolean :active, default: true
    end
  end
end
