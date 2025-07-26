require 'rails_helper'

RSpec.describe Checkout::Stripe::Success, type: :service do
  let(:session_id) { 'cs_test_123' }
  let(:stripe_email) { 'satoshi@example.com' }
  let(:stripe_customer_id) { 'cus_O7lxYiqVso4zB5' }

  let(:mock_customer_details) { instance_double('Stripe::CustomerDetails', email: stripe_email) }
  let(:mock_session) do
    instance_double('Stripe::Checkout::Session',
                    customer_details: mock_customer_details,
                    customer: stripe_customer_id)
  end

  before do
    allow(Stripe::Checkout::Session).to receive(:retrieve).with(session_id).and_return(mock_session)
  end

  subject(:call_service) { described_class.call(session_id) }

  context 'with a valid session_id' do
    it 'retrieves the Stripe checkout session' do
      expect(Stripe::Checkout::Session).to receive(:retrieve).with(session_id)
      call_service
    end

    it 'returns a success result with the checkout session' do
      result = call_service
      expect(result).to be_success
      expect(result.payload).to eq(mock_session)
    end

    it 'does not create or modify any users' do
      expect { call_service }.not_to change(User, :count)
    end

    it 'logs the checkout session' do
      expect(Rails.logger).to receive(:info).with("checkout_session: #{mock_session.inspect}")
      call_service
    end
  end

  context 'with a blank session_id' do
    let(:session_id) { '' }

    it 'raises an error when called' do
      expect { call_service }.to raise_error(RuntimeError, "Session ID is required")
    end
  end

  context 'with a nil session_id' do
    let(:session_id) { nil }

    it 'raises an error when called' do
      expect { call_service }.to raise_error(RuntimeError, "Session ID is required")
    end
  end

  context 'when Stripe raises an InvalidRequestError' do
    before do
      allow(Stripe::Checkout::Session).to receive(:retrieve)
        .with(session_id)
        .and_raise(Stripe::InvalidRequestError.new("No such checkout session", :session))
    end

    it 'logs and raises the error' do
      expect(Rails.logger).to receive(:error).with("Invalid Stripe session: No such checkout session")
      expect { call_service }.to raise_error(RuntimeError, "Invalid session")
    end
  end
end
