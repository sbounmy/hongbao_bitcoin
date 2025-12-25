class AddNamespacedTypeToElements < ActiveRecord::Migration[8.0]
  # Add namespaced type and side to elements:
  # - mnemonic_text -> type: mnemonic/text, side: back
  # - private_key_text -> type: private_key/text, side: back
  # - private_key_qrcode -> type: private_key/qrcode, side: back
  # - public_address_text -> type: public_address/text, side: front
  # - public_address_qrcode -> type: public_address/qrcode, side: front
  # - portrait -> type: portrait, side: front
  # - custom_text -> type: text, side: back (default)

  ELEMENT_TYPES = {
    "mnemonic_text" => "mnemonic/text",
    "private_key_text" => "private_key/text",
    "private_key_qrcode" => "private_key/qrcode",
    "public_address_text" => "public_address/text",
    "public_address_qrcode" => "public_address/qrcode",
    "portrait" => "portrait",
    "custom_text" => "text"
  }.freeze

  ELEMENT_SIDES = {
    "portrait" => "front",
    "public_address_qrcode" => "front",
    "public_address_text" => "front",
    "private_key_qrcode" => "back",
    "private_key_text" => "back",
    "mnemonic_text" => "back",
    "custom_text" => "back"
  }.freeze

  def up
    update_paper_elements
    update_theme_ai_elements
  end

  def down
    remove_type_from_paper_elements
    remove_type_from_theme_ai_elements
  end

  private

  def update_paper_elements
    Paper.find_each do |paper|
      next if paper.elements.blank?

      updated = add_type_to_hash(paper.elements)
      paper.update_column(:elements, updated.deep_stringify_keys) if updated.present?
    end
  end

  def update_theme_ai_elements
    Input::Theme.find_each do |theme|
      next unless theme.metadata.is_a?(Hash) && theme.metadata["ai"].is_a?(Hash)

      updated_ai = add_type_to_hash(theme.metadata["ai"])
      next if updated_ai.blank?

      new_metadata = theme.metadata.deep_dup
      new_metadata["ai"] = updated_ai.deep_stringify_keys
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
      next unless theme.metadata.is_a?(Hash) && theme.metadata["ai"].is_a?(Hash)

      updated_ai = remove_type_from_hash(theme.metadata["ai"])
      next if updated_ai.blank?

      new_metadata = theme.metadata.deep_dup
      new_metadata["ai"] = updated_ai.deep_stringify_keys
      theme.update_column(:metadata, new_metadata)
    end
  end

  def add_type_to_hash(elements)
    elements.each_with_object({}) do |(name, element), hash|
      next unless element.is_a?(Hash)
      hash[name] = element.to_h.merge(
        "type" => ELEMENT_TYPES[name],
        "side" => ELEMENT_SIDES[name] || "back"
      )
    end
  end

  def remove_type_from_hash(elements)
    elements.each_with_object({}) do |(name, element), hash|
      next unless element.is_a?(Hash)
      hash[name] = element.to_h.except("type", "side")
    end
  end
end
