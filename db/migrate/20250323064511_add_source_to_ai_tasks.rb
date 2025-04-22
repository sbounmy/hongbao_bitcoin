class AddSourceToAiTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :ai_tasks, :source, polymorphic: true
  end
end
