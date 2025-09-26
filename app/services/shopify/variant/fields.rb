module Shopify
  module Variant
    class Fields
      FRAGMENT = <<~GRAPHQL
        fragment VariantFields on ProductVariant {
          id
          title
          price
          sku
          availableForSale
          inventoryQuantity
          selectedOptions {
            name
            value
          }
        }
      GRAPHQL

      def self.parse(data)
        return nil if data.blank?

        OpenStruct.new(
          id: data.id,
          title: data.title,
          price: data.price,
          sku: data.sku,
          available_for_sale: data.availableForSale,
          inventory_quantity: data.inventoryQuantity,
          selected_options: parse_selected_options(data.selectedOptions)
        )
      end

      private

      def self.parse_selected_options(options_data)
        return [] if options_data.blank?

        options_data.map do |option|
          OpenStruct.new(
            name: option.name,
            value: option.value
          )
        end
      end
    end
  end
end
