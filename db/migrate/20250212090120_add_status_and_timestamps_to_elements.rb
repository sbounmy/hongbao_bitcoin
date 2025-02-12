class AddStatusAndTimestampsToElements < ActiveRecord::Migration[8.0]
  def change
    add_column :elements, :status, :string
    add_column :elements, :leonardo_created_at, :datetime
    add_column :elements, :leonardo_updated_at, :datetime
  end
end
