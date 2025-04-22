class RenameElementIdToLeonardoIdInAiElements < ActiveRecord::Migration[8.0]
  def change
    rename_column :ai_elements, :element_id, :leonardo_id
  end
end
