class RemoveDeprecatedAiTablesAndColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :papers, :ai_theme_id, :integer
    remove_column :papers, :ai_style_id, :integer, default: 0

    drop_table :ai_elements_themes, if_exists: true
    drop_table :ai_elements, if_exists: true
    drop_table :ai_messages, if_exists: true
    drop_table :ai_tasks, if_exists: true
    drop_table :ai_themes, if_exists: true
  end
end
