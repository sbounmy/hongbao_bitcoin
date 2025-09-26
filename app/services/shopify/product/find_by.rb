module Shopify
  class Product
    class FindBy
      include ShopifyGraphql::Query

      QUERY = <<~GRAPHQL
        #{Fields::FRAGMENT}
        #{Shopify::Variant::Fields::FRAGMENT}

        query($query: String!) {
          products(first: 1, query: $query) {
            edges {
              node {
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
          }
        }
      GRAPHQL

      def call(**args)
        field_key = args.keys.first
        field_value = args.values.first

        return nil unless field_key && field_value

        # Build search query based on field (handle:value, title:value, etc.)
        search_query = case field_key
        when :handle, :title, :product_type, :vendor
          "#{field_key}:\"#{field_value}\""
        else
          raise ArgumentError, "Unsupported field: #{field_key}. Supported fields: handle, title, product_type, vendor"
        end

        Shopify::Client.with_session do
          response = execute(QUERY, query: search_query)
          response.data = parse_data(response.data)
          response
        end
      end

      private

      def parse_data(data)
        return nil if data.blank? || data.products&.edges.blank?

        product_node = data.products.edges.first.node
        product = Fields.parse(product_node)

        # Parse variants and attach to product
        if product_node.variants&.edges.present?
          product.variants = product_node.variants.edges.compact.map do |variant_edge|
            Shopify::Variant::Fields.parse(variant_edge.node)
          end
        end

        product
      end
    end
  end
end
