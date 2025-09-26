require 'rails_helper'

RSpec.describe Shopify::Product::All do
  describe '#call' do
    let(:query_instance) { described_class.new }

    it 'fetches products from Shopify', :vcr do
      VCR.use_cassette('shopify/product/all_query') do
        result = query_instance.call(limit: 10)

        expect(result).to be_a(ShopifyGraphql::Response)
        expect(result.data).to be_an(Array)
        expect(result.errors).to be_nil

        # Verify product structure if we have products
        if result.data.any?
          product = result.data.first
          expect(product).to respond_to(:id)
          expect(product).to respond_to(:title)
          expect(product).to respond_to(:handle)
        end
      end
    end

    it 'extracts product nodes from edges' do
      mock_product = OpenStruct.new(
        id: 'gid://shopify/Product/1',
        title: 'Test Product',
        handle: 'test-product'
      )

      mock_edges = [OpenStruct.new(node: mock_product)]
      mock_products = OpenStruct.new(edges: mock_edges)
      mock_data = OpenStruct.new(products: mock_products)
      mock_response = OpenStruct.new(data: mock_data, errors: nil)

      allow(query_instance).to receive(:execute).and_return(mock_response)

      result = query_instance.call(limit: 10)

      expect(result.data).to eq([mock_product])
      expect(result.data.first.title).to eq('Test Product')
    end

    it 'includes all expected fields in the GraphQL query' do
      query_constant = described_class::QUERY

      # Check that query includes all necessary fields
      expect(query_constant).to include('id')
      expect(query_constant).to include('handle')
      expect(query_constant).to include('title')
      expect(query_constant).to include('description')
      expect(query_constant).to include('tags')
      expect(query_constant).to include('productType')
      expect(query_constant).to include('createdAt')
      expect(query_constant).to include('updatedAt')
      expect(query_constant).to include('images')
      expect(query_constant).to include('variants')
      expect(query_constant).to include('metafields')
      expect(query_constant).to include('pageInfo')
    end

    context 'with error response' do
      it 'returns the response with errors' do
        mock_response = OpenStruct.new(
          data: nil,
          errors: [OpenStruct.new(message: 'API error')]
        )

        allow(query_instance).to receive(:execute).and_return(mock_response)

        result = query_instance.call(limit: 10)

        expect(result.errors).not_to be_nil
        expect(result.data).to be_nil
      end
    end

    context 'with session management' do
      it 'wraps the query execution in a Shopify session' do
        mock_response = OpenStruct.new(data: OpenStruct.new(products: OpenStruct.new(edges: [])), errors: nil)

        expect(Shopify::Client).to receive(:with_session).and_yield
        allow(query_instance).to receive(:execute).and_return(mock_response)

        query_instance.call(limit: 10)
      end
    end
  end
end