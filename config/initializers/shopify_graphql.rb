# Shopify GraphQL configuration
# This gem provides a cleaner interface for GraphQL queries than shopify_api

ShopifyGraphql.configure do |config|
  # The gem primarily handles webhooks, not credentials
  # Credentials are passed when executing queries
  config.webhook_enabled_environments = ['production', 'development']
end