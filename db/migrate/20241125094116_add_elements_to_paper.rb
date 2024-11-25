class AddElementsToPaper < ActiveRecord::Migration[8.0]
  def change
    add_column :papers, :elements, :json
  end
end
