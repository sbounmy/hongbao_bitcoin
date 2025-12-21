class AddTypeToElements < ActiveRecord::Migration[8.0]
  ELEMENT_TYPES = {
    "public_address_qrcode" => "qrcode",
    "public_address_text" => "text",
    "private_key_qrcode" => "qrcode",
    "private_key_text" => "text",
    "mnemonic_text" => "mnemonic",
    "portrait" => "portrait"
  }.freeze

  def up
    add_type_to_paper_elements
    add_type_to_theme_ai_elements
  end

  def down
    remove_type_from_paper_elements
    remove_type_from_theme_ai_elements
  end

  private

  def add_type_to_paper_elements
    Paper.find_each do |paper|
      next if paper.elements.blank?

      updated = add_type_to_hash(paper.elements)
      paper.update_column(:elements, updated.deep_stringify_keys) if updated.present?
    end
  end

  def add_type_to_theme_ai_elements
    Input::Theme.find_each do |theme|
      next if theme.ai.blank?

      updated_ai = add_type_to_hash(theme.ai)
      next if updated_ai.blank?

      new_metadata = theme.metadata.to_h.merge("ai" => updated_ai.deep_stringify_keys)
      theme.update_column(:metadata, new_metadata)
    end
  end

  def remove_type_from_paper_elements
    Paper.find_each do |paper|
      next if paper.elements.blank?

      updated = remove_type_from_hash(paper.elements)
      paper.update_column(:elements, updated.deep_stringify_keys) if updated.present?
    end
  end

  def remove_type_from_theme_ai_elements
    Input::Theme.find_each do |theme|
      next if theme.ai.blank?

      updated_ai = remove_type_from_hash(theme.ai)
      next if updated_ai.blank?

      new_metadata = theme.metadata.to_h.merge("ai" => updated_ai.deep_stringify_keys)
      theme.update_column(:metadata, new_metadata)
    end
  end

  def add_type_to_hash(elements)
    elements.each_with_object({}) do |(name, element), hash|
      next unless element.is_a?(Hash)
      hash[name] = element.to_h.merge("type" => ELEMENT_TYPES[name])
    end
  end

  def remove_type_from_hash(elements)
    elements.each_with_object({}) do |(name, element), hash|
      next unless element.is_a?(Hash)
      hash[name] = element.to_h.except("type")
    end
  end
end
