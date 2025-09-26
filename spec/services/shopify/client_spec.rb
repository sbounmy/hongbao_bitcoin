require 'rails_helper'

RSpec.describe Shopify::Client do
  describe '.session' do
    it 'creates a ShopifyAPI session with credentials' do
      session = described_class.session

      expect(session).to be_a(ShopifyAPI::Auth::Session)
      expect(session.shop).not_to be_nil
      expect(session.access_token).not_to be_nil
    end

    it 'returns the same session instance on subsequent calls' do
      session1 = described_class.session
      session2 = described_class.session

      expect(session1).to be(session2)
    end
  end

  describe '.with_session' do
    it 'activates the session and yields control' do
      expect(ShopifyAPI::Context).to receive(:activate_session).with(instance_of(ShopifyAPI::Auth::Session))

      executed = false
      described_class.with_session do
        executed = true
      end

      expect(executed).to be true
    end

    it 'returns the result of the block' do
      allow(ShopifyAPI::Context).to receive(:activate_session)

      result = described_class.with_session do
        'test result'
      end

      expect(result).to eq('test result')
    end
  end
end