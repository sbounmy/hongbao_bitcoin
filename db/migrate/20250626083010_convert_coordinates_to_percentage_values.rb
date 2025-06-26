class ConvertCoordinatesToPercentageValues < ActiveRecord::Migration[7.1]
  def up
    migrate_coordinates(:up)
  end

  def down
    migrate_coordinates(:down)
  end

  private

  def migrate_coordinates(direction)
    say_with_time("Updating Paper coordinates") do
      Paper.find_each do |paper|
        new_elements = process_elements(paper.elements, direction)
        # Use update_column to bypass callbacks and prevent serialization errors.
        paper.update_column(:elements, new_elements)
      end
    end

    say_with_time("Updating Input::Theme coordinates") do
      Input::Theme.find_each do |theme|
        next unless theme.metadata&.key?('ai')

        new_metadata = theme.metadata.deep_dup
        new_metadata['ai'] = process_elements(new_metadata['ai'], direction)
        # Use update_column here as well to prevent errors.
        theme.update_column(:metadata, new_metadata)
      end
    end
  end

  def process_elements(elements, direction)
    return elements unless elements.is_a?(Hash)

    elements.each_with_object({}) do |(element_key, element_details), new_elements|
      unless element_details.is_a?(Hash)
        new_elements[element_key] = element_details
        next
      end

      # We do this to prevent serialization errors
      new_details = element_details.to_h

      # Transform x and y for sure
      %w[x y].each do |key|
        next unless new_details.key?(key) && new_details[key].present?
        original_value = new_details[key].to_f

        new_value = calculate_new_value(original_value, direction)
        new_details[key] = new_details[key].is_a?(String) ? new_value.to_s : new_value
      end

      # we gotta transform size for qrcode elements only
      if element_key.to_s.include?('qrcode')
        if new_details.key?('size') && new_details['size'].present?
          original_value = new_details['size'].to_f
          new_value = calculate_new_value(original_value, direction)
          new_details['size'] = new_details['size'].is_a?(String) ? new_value.to_s : new_value
        end
      end

      new_elements[element_key] = new_details
    end
  end

  def calculate_new_value(value, direction)
    if direction == :up
      value.between?(0, 1) ? (value * 100) : value
    else # direction must be :down
      value > 1 ? value / 100.0 : value
    end
  end
end
