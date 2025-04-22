class AddUserToGenerations < ActiveRecord::Migration[8.0]
  def change
    add_reference :ai_generations, :user, foreign_key: true
  end
end
