class DropAiFaceSwaps < ActiveRecord::Migration[8.0]
  def up
    drop_table :ai_face_swaps
  end

  def down
    create_table :ai_face_swaps do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
