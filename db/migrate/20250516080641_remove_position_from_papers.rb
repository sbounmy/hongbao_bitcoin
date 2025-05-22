class RemovePositionFromPapers < ActiveRecord::Migration[8.0]
  def change
    remove_column :papers, :position
  end
end
