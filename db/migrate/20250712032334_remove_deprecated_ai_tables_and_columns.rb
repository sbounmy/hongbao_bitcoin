class RemoveDeprecatedAiTablesAndColumns < ActiveRecord::Migration[8.0]
  def change
    drop_table :ai_elements_themes
    drop_table :ai_elements
    drop_table :ai_messages
    drop_table :ai_tasks
    drop_table :ai_themes
    remove_column :papers, :ai_style_id, :integer, default: 0
    remove_column :papers, :ai_theme_id, :integer
  end
end
