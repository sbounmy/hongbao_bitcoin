class UnifyElementPropertiesToWidthHeight < ActiveRecord::Migration[8.0]
  def up
    # Update Input::Theme records
    update_inputs

    # Update Paper records
    update_papers
  end

  def down
    # Reverse Input::Theme records
    revert_inputs

    # Reverse Paper records
    revert_papers
  end

  private

  def update_inputs
    Input.where(type: "Input::Theme").find_each do |theme|
      next unless theme.metadata["ai"].present?

      ai_data = theme.metadata["ai"]
      modified = false

      ai_data.each do |element_type, properties|
        next unless properties.is_a?(Hash)

        if qr_code_element?(element_type)
          # QR codes: size → width + height (maintain square on 2:1 aspect ratio templates)
          # Bank notes are typically ~2:1 (width:height), so height needs to be 2x width percentage
          if properties["size"].present?
            size_value = properties["size"].to_f
            properties["width"] = size_value
            properties["height"] = size_value * 2  # Double height % to maintain square on 2:1 template
            properties.delete("size")
            modified = true
          end
          # Also remove max_text_width if present (shouldn't be there but clean it up)
          if properties["max_text_width"].present?
            properties.delete("max_text_width")
            modified = true
          end

        elsif text_element?(element_type)
          # Text elements: max_text_width → width, keep size for font
          if properties["max_text_width"].present?
            properties["width"] = properties["max_text_width"]
            properties.delete("max_text_width")
            modified = true
          end
          # Ensure height exists for text bounding box
          unless properties["height"].present?
            properties["height"] = 10  # Default height percentage for text box
            modified = true
          end

          # Adjust font size to compensate for property changes
          # Old size values were too large, scale them down
          if properties["size"].present?
            old_size = properties["size"].to_f
            # Scale down font sizes based on element type
            new_size = case element_type
            when "public_address_text", "private_key_text"
              1.8  # Smaller font for addresses/keys
            when "mnemonic_text"
              1.6  # Even smaller for mnemonic
            else
              old_size * 0.1  # Generic fallback: scale down by 90%
            end
            properties["size"] = new_size
            modified = true
          end

        elsif element_type == "portrait"
          # Portrait: ensure width + height exist with defaults
          unless properties["width"].present? && properties["height"].present?
            properties["width"] ||= 18
            properties["height"] ||= 23
            modified = true
          end
          # Clean up any legacy properties
          if properties["size"].present?
            properties.delete("size")
            modified = true
          end
          if properties["max_text_width"].present?
            properties.delete("max_text_width")
            modified = true
          end
        end
      end

      if modified
        theme.update_column(:metadata, theme.metadata)
        puts "Updated Input::Theme ##{theme.id} (#{theme.name})"
      end
    end
  end

  def update_papers
    Paper.find_each do |paper|
      next unless paper.elements.present?

      elements_data = paper.elements
      modified = false

      elements_data.each do |element_type, properties|
        next unless properties.is_a?(Hash)

        if qr_code_element?(element_type)
          if properties["size"].present?
            size_value = properties["size"].to_f
            properties["width"] = size_value
            properties["height"] = size_value * 2  # Double height % to maintain square on 2:1 template
            properties.delete("size")
            modified = true
          end
          if properties["max_text_width"].present?
            properties.delete("max_text_width")
            modified = true
          end

        elsif text_element?(element_type)
          if properties["max_text_width"].present?
            properties["width"] = properties["max_text_width"]
            properties.delete("max_text_width")
            modified = true
          end
          # Ensure height exists for text bounding box
          unless properties["height"].present?
            properties["height"] = 10
            modified = true
          end

          # Adjust font size to compensate for property changes
          if properties["size"].present?
            old_size = properties["size"].to_f
            new_size = case element_type
            when "public_address_text", "private_key_text"
              1.8
            when "mnemonic_text"
              1.6
            else
              old_size * 0.1
            end
            properties["size"] = new_size
            modified = true
          end
        end
      end

      if modified
        paper.update_column(:elements, elements_data)
        puts "Updated Paper ##{paper.id}"
      end
    end
  end

  def revert_inputs
    Input.where(type: "Input::Theme").find_each do |theme|
      next unless theme.metadata["ai"].present?

      ai_data = theme.metadata["ai"]
      modified = false

      ai_data.each do |element_type, properties|
        next unless properties.is_a?(Hash)

        if qr_code_element?(element_type)
          # width + height → size (use width)
          if properties["width"].present?
            properties["size"] = properties["width"]
            properties.delete("width")
            properties.delete("height")
            modified = true
          end

        elsif text_element?(element_type)
          # width → max_text_width, keep size, remove height
          if properties["width"].present?
            properties["max_text_width"] = properties["width"]
            properties.delete("width")
            modified = true
          end
          if properties["height"].present?
            properties.delete("height")  # Remove height added for text box
            modified = true
          end
          # Keep size as-is
        end
      end

      if modified
        theme.update_column(:metadata, theme.metadata)
        puts "Reverted Input::Theme ##{theme.id} (#{theme.name})"
      end
    end
  end

  def revert_papers
    Paper.find_each do |paper|
      next unless paper.elements.present?

      elements_data = paper.elements
      modified = false

      elements_data.each do |element_type, properties|
        next unless properties.is_a?(Hash)

        if qr_code_element?(element_type)
          if properties["width"].present?
            properties["size"] = properties["width"]
            properties.delete("width")
            properties.delete("height")
            modified = true
          end

        elsif text_element?(element_type)
          if properties["width"].present?
            properties["max_text_width"] = properties["width"]
            properties.delete("width")
            modified = true
          end
          if properties["height"].present?
            properties.delete("height")
            modified = true
          end
        end
      end

      if modified
        paper.update_column(:elements, elements_data)
        puts "Reverted Paper ##{paper.id}"
      end
    end
  end

  def qr_code_element?(element_type)
    element_type.to_s.include?("qrcode")
  end

  def text_element?(element_type)
    element_type.to_s.include?("text") && element_type != "max_text_width"
  end
end
