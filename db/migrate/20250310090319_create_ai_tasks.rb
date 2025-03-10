class CreateAiTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_tasks do |t|
      t.string :external_id, null: false
      t.string :status, default: 'pending'
      t.references :user, foreign_key: true, null: false
      t.string :type, null: false
      t.string :prompt

      t.timestamps
    end

    add_index :ai_tasks, [ :type, :external_id ]
  end
end
