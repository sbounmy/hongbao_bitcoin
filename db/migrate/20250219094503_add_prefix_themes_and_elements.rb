class AddPrefixThemesAndElements < ActiveRecord::Migration[8.0]
  def change
    rename_table :themes, :ai_themes
    rename_table :elements, :ai_elements
    rename_table :elements_themes, :ai_elements_themes
  end
end
