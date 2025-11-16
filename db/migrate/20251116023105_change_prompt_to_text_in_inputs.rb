class ChangePromptToTextInInputs < ActiveRecord::Migration[8.0]
  def up
    change_column :inputs, :prompt, :text
  end

  def down
    change_column :inputs, :prompt, :string
  end
end
