class AddPathAndSettingsToThemes < ActiveRecord::Migration[8.0]
  def change
    change_table :ai_themes do |t|
      t.string :path
      t.json :settings, default: '{}'
    end
  end
end
