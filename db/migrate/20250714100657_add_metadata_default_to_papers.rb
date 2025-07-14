class AddMetadataDefaultToPapers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :papers, :metadata, from: {}, to: "{}"
  end
end
