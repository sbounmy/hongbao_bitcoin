class AddInputIdsToPapers < ActiveRecord::Migration[8.0]
  def change
    change_table :papers do |t|
      t.json :input_ids, null: false, default: []
      t.check_constraint "JSON_TYPE(input_ids) = 'array'", name: 'paper_input_ids_is_array'
    end
  end
end
