module Shopify
  class Shop < Base
    class << self
      def current
        execute_query(Shop::Current)
      end
    end
  end
end