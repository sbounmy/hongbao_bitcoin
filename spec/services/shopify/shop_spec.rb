require 'rails_helper'

RSpec.describe Shopify::Shop do
  describe '.current' do
    it 'returns shop information', vcr: { cassette_name: 'shopify/shop/current' } do
      shop = described_class.current

      expect(shop).not_to be_nil
      expect(shop).to respond_to(:name)
      expect(shop).to respond_to(:email)
      expect(shop).to respond_to(:currencyCode)
      expect(shop).to respond_to(:primaryDomain)

      # Check nested structure if present
      if shop.primaryDomain
        expect(shop.primaryDomain).to respond_to(:url)
        expect(shop.primaryDomain).to respond_to(:host)
      end
    end
  end
end