module Shopify
  class Base
    class << self
      protected

      def execute_query(query_class, **args)
        response = query_class.new.call(**args)

        if response.errors.nil?
          response.data
        else
          handle_errors(response)
        end
      end

      def handle_errors(response)
        error_messages = if response.errors.respond_to?(:map)
          response.errors.map { |e| e.respond_to?(:message) ? e.message : e.to_s }.join(", ")
        else
          response.errors.to_s
        end

        Rails.logger.error "Shopify GraphQL Error: #{error_messages}"
        raise ShopifyError, error_messages
      end
    end
  end

  class ShopifyError < StandardError; end
end
