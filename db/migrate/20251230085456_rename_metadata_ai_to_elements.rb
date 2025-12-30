class RenameMetadataAiToElements < ActiveRecord::Migration[8.0]
  def up
    # Move metadata.ai to metadata.elements
    execute <<-SQL
      UPDATE inputs
      SET metadata = json_set(
        json_remove(metadata, '$.ai'),
        '$.elements',
        json_extract(metadata, '$.ai')
      )
      WHERE type = 'Input::Theme'
        AND json_extract(metadata, '$.ai') IS NOT NULL
    SQL

    # Fix any JSON strings that should be objects
    # (json_extract returns strings as-is, we need to parse them)
    Input::Theme.find_each do |theme|
      elements = theme.metadata["elements"]
      if elements.is_a?(String)
        parsed = JSON.parse(elements) rescue elements
        theme.metadata["elements"] = parsed
        theme.save
      end
    end
  end

  def down
    execute <<-SQL
      UPDATE inputs
      SET metadata = json_set(
        json_remove(metadata, '$.elements'),
        '$.ai',
        json_extract(metadata, '$.elements')
      )
      WHERE type = 'Input::Theme'
        AND json_extract(metadata, '$.elements') IS NOT NULL
    SQL
  end
end
