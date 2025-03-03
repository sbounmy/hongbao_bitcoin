class AddTaskIdToPapers < ActiveRecord::Migration[8.0]
  def change
    add_column :papers, :task_id, :string
  end
end
