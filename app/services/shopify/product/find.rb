module Shopify
  class Product
    class Find
      include ShopifyGraphql::Query

      QUERY = <<~GRAPHQL
        #{Fields::FRAGMENT}
        #{Shopify::Variant::Fields::FRAGMENT}

        query($id: ID!) {
          product(id: $id) {
            ...ProductFields
            variants(first: 20) {
              edges {
                node {
                  ...VariantFields
                }
              }
            }
          }
        }
      GRAPHQL

      def call(id:)
        Shopify::Client.with_session do
          response = execute(QUERY, id: id)
          response.data = parse_data(response.data)
          response
        end
      end

      private

      def parse_data(data)
        return nil if data.blank? || data.product.blank?

        product = Fields.parse(data.product)

        # Parse variants and attach to product
        if data.product.variants&.edges.present?
          product.variants = data.product.variants.edges.compact.map do |variant_edge|
            Shopify::Variant::Fields.parse(variant_edge.node)
          end
        end

        product
      end
    end
  end
end
