class ConvertYamlMetadataToJson < ActiveRecord::Migration[8.0]
  def up
    [ Paper, Input, Token ].each do |model|
      convert_yaml_metadata_for(model)
    end
  end

  def down
    # This migration is not reversible as we're converting from YAML to JSON
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def convert_yaml_metadata_for(model)
    model.find_each do |record|
      next if record.metadata.blank?

      # Check if metadata is a YAML string
      if record.metadata.is_a?(String) && record.metadata.include?("---\n")
        begin
          # Parse YAML and convert to JSON
          yaml_data = YAML.load(record.metadata)
          record.update_column(:metadata, yaml_data)
          puts "Converted metadata for #{model.name} ##{record.id}"
        rescue => e
          puts "Failed to convert metadata for #{model.name} ##{record.id}: #{e.message}"
        end
      end
    end
  end
end
