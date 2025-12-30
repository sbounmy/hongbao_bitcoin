class RemoveMetadataUiFromThemes < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE inputs
      SET metadata = json_remove(metadata, '$.ui')
      WHERE type = 'Input::Theme'
        AND json_extract(metadata, '$.ui') IS NOT NULL
    SQL
  end

  def down
    # Cannot restore - data is lost
  end
end
