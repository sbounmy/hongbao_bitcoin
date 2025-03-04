class CreateFaceSwapTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :face_swap_tasks do |t|
      t.string :task_id, null: false
      t.string :task_status, default: 'pending'
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end

    add_index :face_swap_tasks, :task_id, unique: true
  end
end
