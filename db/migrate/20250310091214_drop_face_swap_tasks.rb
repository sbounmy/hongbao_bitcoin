class DropFaceSwapTasks < ActiveRecord::Migration[8.0]
  def up
    drop_table :face_swap_tasks
  end

  def down
    create_table :face_swap_tasks do |t|
      t.string "task_id", null: false
      t.string "task_status", default: "pending"
      t.integer "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "task_id" ], name: "index_face_swap_tasks_on_task_id", unique: true
      t.index [ "user_id" ], name: "index_face_swap_tasks_on_user_id"
    end
  end
end
