module Shopify
  class Product < Base
    class << self
      def all(limit: 50)
        execute_query(Product::All, limit: limit)
      end
    end
  end
end
