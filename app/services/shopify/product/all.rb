module Shopify
  class Product
    class All
      include ShopifyGraphql::Query

      QUERY = <<~GRAPHQL
        #{Fields::FRAGMENT}
        #{Shopify::Variant::Fields::FRAGMENT}

        query($first: Int!, $cursor: String) {
          products(first: $first, after: $cursor) {
            edges {
              cursor
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
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      GRAPHQL

      def call(limit:, paginate: false)
        Shopify::Client.with_session do
          response = execute(QUERY, first: limit)
          data = parse_data(response.data.products.edges)

          # Handle pagination if requested
          if paginate && response.data.products.pageInfo.hasNextPage
            cursor = response.data.products.pageInfo.endCursor

            while response.data.products.pageInfo.hasNextPage
              response = execute(QUERY, first: limit, cursor: cursor)
              data += parse_data(response.data.products.edges)
              cursor = response.data.products.pageInfo.endCursor
            end
          end

          response.data = data
          response
        end
      end

      private

      def parse_data(edges)
        return [] if edges.blank?

        edges.compact.map do |edge|
          product = Fields.parse(edge.node)

          # Parse variants and attach to product
          if edge.node.variants&.edges.present?
            product.variants = edge.node.variants.edges.compact.map do |variant_edge|
              Shopify::Variant::Fields.parse(variant_edge.node)
            end
          end

          product
        end
      end
    end
  end
end
