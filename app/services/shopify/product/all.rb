module Shopify
  class Product
    class All
      include ShopifyGraphql::Query

      def initialize
        # Session is managed by Shopify::Client
      end

      QUERY = <<~GRAPHQL
        query($first: Int!) {
          products(first: $first) {
            edges {
              node {
                id
                handle
                title
                description
                tags
                productType
                createdAt
                updatedAt
                images(first: 10) {
                  edges {
                    node {
                      url
                      altText
                    }
                  }
                }
                variants(first: 20) {
                  edges {
                    node {
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
                  }
                }
                metafields(first: 10) {
                  edges {
                    node {
                      namespace
                      key
                      value
                      type
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

      def call(limit:)
        Shopify::Client.with_session do
          response = execute(QUERY, first: limit)

          # Extract just the product nodes from the edges
          if response.errors.nil?
            response.data = response.data.products.edges.map(&:node)
          end

          response
        end
      end
    end
  end
end
