module Shopify
  class Product
    class Fields
      FRAGMENT = <<~GRAPHQL
        fragment ProductFields on Product {
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
      GRAPHQL

      def self.parse(data)
        return nil if data.blank?

        OpenStruct.new(
          id: data.id,
          handle: data.handle,
          title: data.title,
          description: data.description,
          tags: data.tags,
          product_type: data.productType,
          created_at: data.createdAt,
          updated_at: data.updatedAt,
          images: parse_images(data.images),
          metafields: parse_metafields(data.metafields),
          variants: [] # Will be populated separately if needed
        )
      end

      private

      def self.parse_images(images_data)
        return [] if images_data.blank? || images_data.edges.blank?

        images_data.edges.compact.map do |edge|
          OpenStruct.new(
            url: edge.node.url,
            alt_text: edge.node.altText
          )
        end
      end

      def self.parse_metafields(metafields_data)
        return [] if metafields_data.blank? || metafields_data.edges.blank?

        metafields_data.edges.compact.map do |edge|
          OpenStruct.new(
            namespace: edge.node.namespace,
            key: edge.node.key,
            value: edge.node.value,
            type: edge.node.type
          )
        end
      end
    end
  end
end
