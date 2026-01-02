class AddUserToInputItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :input_items, :user, foreign_key: true
  end
end
