# frozen_string_literal: true

module Canva
  class ItemComponent < ApplicationComponent
    # Drawer mapping - easy to change in one place
    DRAWER_MAP = {
      /public/ => "style-drawer",
      /private|mnemonic/ => "keys-drawer",
      /portrait/ => "photo-drawer"
    }.freeze

    attr_reader :name, :item

    def initialize(name:, item:)
      @name = name
      @item = item.with_indifferent_access
    end

    # Factory method to create the right component based on item type
    # Options are passed through to specific components (e.g., placeholder for portrait)
    def self.for(name:, item:, **options)
      item = item.with_indifferent_access

      case item[:type]&.to_s
      when "qrcode" then QrcodeItemComponent.new(name:, item:)
      when "mnemonic", "text" then TextItemComponent.new(name:, item:)
      when "portrait" then PortraitItemComponent.new(name:, item:, **options)
      else TextItemComponent.new(name:, item:) # fallback
      end
    end

    private

    def drawer
      DRAWER_MAP.find { |pattern, _| name.to_s.match?(pattern) }&.last
    end

    def controller_name
      raise NotImplementedError, "Subclasses must implement #controller_name"
    end

    def data_prefix
      controller_name.tr("-", "_")
    end

    def common_data
      {
        controller: controller_name,
        canva_target: "canvaItem",
        "#{data_prefix}_x_value": item[:x],
        "#{data_prefix}_y_value": item[:y],
        "#{data_prefix}_name_value": name.to_s.camelize(:lower),
        "#{data_prefix}_width_value": item[:width],
        "#{data_prefix}_height_value": item[:height],
        "#{data_prefix}_hidden_value": item[:hidden],
        "#{data_prefix}_presence_value": item.fetch(:presence, true),
        "#{data_prefix}_drawer_value": drawer
      }.compact
    end
  end
end
