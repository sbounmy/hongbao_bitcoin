module Shopify
  class Client
    class << self
      def session
        @session ||= ShopifyAPI::Auth::Session.new(
          shop: Rails.application.credentials.dig(:shopify, :domain),
          access_token: Rails.application.credentials.dig(:shopify, :access_token)
        )
      end

      def with_session
        if session
          ShopifyAPI::Context.activate_session(session)
          yield
        else
          raise "Shopify credentials not configured. Run: rails credentials:edit"
        end
      end
    end
  end
end
