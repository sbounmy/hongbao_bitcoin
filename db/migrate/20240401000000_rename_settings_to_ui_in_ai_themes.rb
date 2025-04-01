class RenameSettingsToUiInAiThemes < ActiveRecord::Migration[8.0]
  def change
    rename_column :ai_themes, :settings, :ui
  end
end
