class ChangeDefaultToInputIdsInPapers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :papers, :input_item_ids, from: "[]", to: []
  end
end
