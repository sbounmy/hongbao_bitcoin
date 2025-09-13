class ConvertMetadataToJsonFormat < ActiveRecord::Migration[8.0]
  def up
    # Convert tags metadata from double-encoded JSON string to proper JSON
    # The data is currently stored as a JSON string containing another JSON string
    execute <<-SQL
      UPDATE tags
      SET metadata = CASE
        WHEN metadata IS NOT NULL AND json_type(metadata) = 'text' AND json_valid(json_extract(metadata, '$'))
        THEN json(json_extract(metadata, '$'))
        ELSE metadata
      END
      WHERE metadata IS NOT NULL
    SQL

    execute <<-SQL
      UPDATE papers
      SET metadata = CASE
        WHEN metadata IS NOT NULL AND json_type(metadata) = 'text' AND json_valid(json_extract(metadata, '$'))
        THEN json(json_extract(metadata, '$'))
        ELSE metadata
      END
      WHERE metadata IS NOT NULL
    SQL

    execute <<-SQL
      UPDATE inputs
      SET metadata = CASE
        WHEN metadata IS NOT NULL AND json_type(metadata) = 'text' AND json_valid(json_extract(metadata, '$'))
        THEN json(json_extract(metadata, '$'))
        ELSE metadata
      END
      WHERE metadata IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL
      UPDATE tags
      SET metadata = json_quote(metadata)
      WHERE metadata IS NOT NULL
      AND json_type(metadata) = 'object'
    SQL

    execute <<-SQL
      UPDATE papers
      SET metadata = json_quote(metadata)
      WHERE metadata IS NOT NULL
      AND json_type(metadata) = 'object'
    SQL

    execute <<-SQL
      UPDATE inputs
      SET metadata = json_quote(metadata)
      WHERE metadata IS NOT NULL
      AND json_type(metadata) = 'object'
    SQL
  end
end
