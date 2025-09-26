require 'rails_helper'

RSpec.describe Shopify::Product::Find do
  describe '#call' do
    let(:query_instance) { described_class.new }

    it 'fetches a product by ID from Shopify', :vcr do
      VCR.use_cassette('shopify/product/find_by_id', record: :new_episodes) do
        # Use a real product ID from your Shopify store
        product_id = 'gid://shopify/Product/9692959244616'
        result = query_instance.call(id: product_id)

        expect(result).to be_a(ShopifyGraphql::Response)
        expect(result.errors).to be_nil
        expect(result.data).not_to be_nil

        # Verify the parsed product structure
        product = result.data
        expect(product.id).to eq(product_id)
        expect(product.title).to be_present
        expect(product.handle).to be_present
        expect(product.variants).to be_an(Array)

        # Verify variant structure if present
        if product.variants.any?
          variant = product.variants.first
          expect(variant).to respond_to(:id)
          expect(variant).to respond_to(:price)
          expect(variant).to respond_to(:title)
        end
      end
    end

    it 'returns nil when product is not found', :vcr do
      VCR.use_cassette('shopify/product/find_not_found') do
        result = query_instance.call(id: 'gid://shopify/Product/nonexistent')

        expect(result).to be_a(ShopifyGraphql::Response)
        expect(result.data).to be_nil
      end
    end

    it 'includes all expected fields in the GraphQL query' do
      query = described_class::QUERY

      # Verify fragments are included
      expect(query).to include('fragment ProductFields')
      expect(query).to include('fragment VariantFields')

      # Verify query structure
      expect(query).to include('query($id: ID!)')
      expect(query).to include('product(id: $id)')
      expect(query).to include('...ProductFields')
      expect(query).to include('...VariantFields')
      expect(query).to include('variants(first: 20)')
    end

    it 'wraps the query execution in a Shopify session' do
      expect(Shopify::Client).to receive(:with_session).and_yield
      allow(query_instance).to receive(:execute).and_return(
        OpenStruct.new(data: OpenStruct.new(product: nil), errors: nil)
      )

      query_instance.call(id: 'gid://shopify/Product/123')
    end
  end
end
