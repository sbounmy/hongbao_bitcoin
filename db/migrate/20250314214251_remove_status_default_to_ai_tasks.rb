class RemoveStatusDefaultToAiTasks < ActiveRecord::Migration[8.0]
  def change
    change_column_default :ai_tasks, :status, from: "pending", to: nil
  end
end
