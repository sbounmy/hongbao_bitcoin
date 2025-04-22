class AddRequestAndResponseToAiTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_tasks, :request, :json
    add_column :ai_tasks, :response, :json
  end
end
