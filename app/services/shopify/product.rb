module Shopify
  class Product < Base
    class << self
      def all(limit: 50)
        execute_query(Product::All, limit: limit)
      end

      def find(id)
        return nil unless id

        execute_query(Product::Find, id: id)
      end

      def find_by(**args)
        return nil if args.empty?

        execute_query(Product::FindBy, **args)
      end
    end
  end
end
