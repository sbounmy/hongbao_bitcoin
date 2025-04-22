class CreateJoinTableThemesElements < ActiveRecord::Migration[8.0]
  def change
    create_join_table :themes, :elements do |t|
      t.index [ :theme_id, :element_id ]
      t.index [ :element_id, :theme_id ]
    end
  end
end
