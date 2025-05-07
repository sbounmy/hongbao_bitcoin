class AddMessageToPapers < ActiveRecord::Migration[8.0]
  def change
    change_table :papers do |t|
      t.references :message, foreign_key: { to_table: :messages }
    end
  end
end
