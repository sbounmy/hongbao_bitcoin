class AddUserToPapers < ActiveRecord::Migration[8.0]
  def change
    add_reference :papers, :user, foreign_key: true
    add_column :papers, :public, :boolean, default: false
  end
end
