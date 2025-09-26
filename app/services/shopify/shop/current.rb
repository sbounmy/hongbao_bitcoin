module Shopify
  class Shop
    class Current
      include ShopifyGraphql::Query

      QUERY = <<~GRAPHQL
        query {
          shop {
            name
            email
            currencyCode
            primaryDomain {
              url
              host
            }
            billingAddress {
              country
              countryCodeV2
            }
          }
        }
      GRAPHQL

      def call
        Shopify::Client.with_session do
          response = execute(QUERY)

          # Return just the shop data
          if response.errors.nil?
            response.data = response.data.shop
          end

          response
        end
      end
    end
  end
end
