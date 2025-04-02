class AddAiStyleAndThemeToPapers < ActiveRecord::Migration[8.0]
  def change
    rename_column :papers, :style, :ai_style_id
    add_reference :papers, :ai_theme, foreign_key: true
  end
end
