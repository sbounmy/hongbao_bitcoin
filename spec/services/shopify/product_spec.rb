require 'rails_helper'

RSpec.describe Shopify::Product do
  describe '.all' do
    it 'returns an array of products', vcr: { cassette_name: 'shopify/product/all' } do
      products = described_class.all

      expect(products).to be_an(Array)
      expect(products).not_to be_empty

      # Check the structure of the first product
      first_product = products.first
      expect(first_product).to respond_to(:id)
      expect(first_product).to respond_to(:title)
      expect(first_product).to respond_to(:handle)
      expect(first_product).to respond_to(:description)
      expect(first_product).to respond_to(:tags)
      expect(first_product).to respond_to(:productType)
      expect(first_product).to respond_to(:createdAt)
      expect(first_product).to respond_to(:updatedAt)
      expect(first_product).to respond_to(:images)
      expect(first_product).to respond_to(:variants)
      expect(first_product).to respond_to(:metafields)
    end

    it 'accepts a limit parameter', vcr: { cassette_name: 'shopify/product/all_with_limit' } do
      products = described_class.all(limit: 2)

      expect(products).to be_an(Array)
      expect(products.size).to be <= 2
    end

    context 'when Shopify returns an error' do
      before do
        allow_any_instance_of(Shopify::Product::All).to receive(:call).and_return(
          OpenStruct.new(errors: [ OpenStruct.new(message: 'Invalid API key') ])
        )
      end

      it 'raises a ShopifyError' do
        expect { described_class.all }.to raise_error(Shopify::ShopifyError, 'Invalid API key')
      end
    end
  end
end
