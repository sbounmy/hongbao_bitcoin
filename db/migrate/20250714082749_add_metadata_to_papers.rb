class AddMetadataToPapers < ActiveRecord::Migration[8.0]
  def change
    add_column :papers, :metadata, :json, default: {}
  end
end
