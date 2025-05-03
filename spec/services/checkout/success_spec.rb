require 'rails_helper'

RSpec.describe Checkout::Success, type: :service do
  let(:session_id) { 'cs_test_123' }
  let(:email) { 'satoshi@example.com' }
  let(:stripe_customer_id) { 'cus_O7lxYiqVso4zB5' }

  let(:mock_customer_details) { instance_double('Stripe::CustomerDetails', email: email) }
  let(:mock_session) do
    instance_double('Stripe::Checkout::Session',
                    customer_details: mock_customer_details,
                    customer: stripe_customer_id)
  end

  # Stub the main dependency: Stripe Checkout Session retrieval
  before do
    allow(Stripe::Checkout::Session).to receive(:retrieve).with(session_id).and_return(mock_session)
  end

  subject(:call_service) { described_class.call(session_id, authenticated: authenticated) }

  context 'when the user already exists' do
    context 'when authenticated is true' do
      let(:authenticated) { true }


      it 'does not create a new user' do
        expect {
          call_service
        }.not_to change(User, :count)
      end

      it 'returns a success result with the existing user' do
        result = call_service
        expect(result).to be_success
        expect(result.payload).to eq(users(:satoshi))
      end

      it 'updates the user stripe customer id' do
        users(:satoshi).update(stripe_customer_id: nil)
        expect {
          call_service
        }.to change { users(:satoshi).reload.stripe_customer_id }.from(nil).to('cus_O7lxYiqVso4zB5')
      end
    end

    context 'when authenticated is false' do
      let(:authenticated) { false }

      it 'does not create a new user' do
        expect {
          call_service
        }.not_to change(User, :count)
      end

      it 'returns a success result with the existing user' do
        result = call_service
        expect(result).to be_success
        expect(result.payload).to eq(users(:satoshi))
      end
    end
  end

  context 'when the user does not exist' do
    context 'when authenticated is false' do
      let(:authenticated) { false }
      let(:stripe_customer_id) { 'cus_new-user' }
      let(:email) { 'new-user@example.com' }

      it 'creates a new user with correct details' do
        expect {
          call_service
        }.to change(User, :count).by(1)
        user = User.last
        expect(user.email).to eq(email)
        expect(user.stripe_customer_id).to eq(stripe_customer_id)
      end

      it 'returns a success result with the new user' do
        result = call_service
        expect(result).to be_success
        expect(result.payload).to eq(User.last)
      end
    end

    context 'when authenticated is true' do
      let(:authenticated) { true }

      it 'does not create a new user' do
        expect {
          call_service
        }.not_to change(User, :count)
      end

      it 'returns a success result with User' do
        result = call_service
        expect(result).to be_success
        expect(result.payload).to be_a(User)
      end
    end
  end
end
