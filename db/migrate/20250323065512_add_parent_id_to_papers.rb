class AddParentIdToPapers < ActiveRecord::Migration[8.0]
  def change
    add_reference :papers, :parent, foreign_key: { to_table: :papers }
  end
end
