require 'rails_helper'

RSpec.describe Shopify::Base do
  describe '.execute_query' do
    context 'when the query succeeds', vcr: { cassette_name: 'shopify/base/shop_success' } do
      it 'returns the data from the response' do
        result = Shopify::Shop.current

        expect(result).not_to be_nil
        expect(result).to respond_to(:name)
        expect(result).to respond_to(:email)
        expect(result).to respond_to(:currencyCode)
        expect(result).to respond_to(:primaryDomain)
      end
    end

    context 'when the query fails' do
      # Create a test query class that will intentionally fail
      let(:invalid_query_class) do
        Class.new do
          include ShopifyGraphql::Query

          QUERY = <<~GRAPHQL
            query {
              invalidField {
                notExisting
              }
            }
          GRAPHQL

          def call
            Shopify::Client.with_session do
              execute(QUERY)
            end
          end
        end
      end

      let(:test_class) do
        Class.new(Shopify::Base) do
          def self.test_invalid_query(query_class)
            execute_query(query_class)
          end
        end
      end

      it 'raises a ShopifyError with the error message', vcr: { cassette_name: 'shopify/base/invalid_query' } do
        expect do
          test_class.test_invalid_query(invalid_query_class)
        end.to raise_error(Shopify::ShopifyError)
      end

      it 'logs the error', vcr: { cassette_name: 'shopify/base/invalid_query_logging' } do
        expect(Rails.logger).to receive(:error).with(/Shopify GraphQL Error:/)

        expect { test_class.test_invalid_query(invalid_query_class) }.to raise_error(Shopify::ShopifyError)
      end
    end
  end

  describe 'Shopify::Shop integration' do
    it 'inherits from Base and uses execute_query', vcr: { cassette_name: 'shopify/base/shop_inheritance' } do
      expect(Shopify::Shop).to be < Shopify::Base

      shop = Shopify::Shop.current
      expect(shop).not_to be_nil
    end
  end
end
