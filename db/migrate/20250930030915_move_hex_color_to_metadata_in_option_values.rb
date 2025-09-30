class MoveHexColorToMetadataInOptionValues < ActiveRecord::Migration[8.0]
  def up
    # Add metadata column if it doesn't exist
    unless column_exists?(:option_values, :metadata)
      add_column :option_values, :metadata, :json, default: {}
    end

    # Migrate existing hex_color values to metadata
    OptionValue.reset_column_information
    OptionValue.find_each do |option_value|
      if option_value.hex_color.present?
        option_value.update_column(:metadata,
          (option_value.metadata || {}).merge('color' => option_value.hex_color)
        )
      end
    end

    # Remove hex_color column
    remove_column :option_values, :hex_color
  end

  def down
    # Add hex_color column back
    add_column :option_values, :hex_color, :string

    # Migrate metadata color back to hex_color
    OptionValue.reset_column_information
    OptionValue.find_each do |option_value|
      if option_value.metadata&.dig('color').present?
        option_value.update_column(:hex_color, option_value.metadata['color'])
      end
    end

    # Optionally remove metadata column if it only contained color
    # remove_column :option_values, :metadata
  end
end
