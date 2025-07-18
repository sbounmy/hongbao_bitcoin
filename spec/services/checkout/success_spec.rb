require 'rails_helper'

RSpec.describe Checkout::Stripe::Success, type: :service do
  let(:session_id) { 'cs_test_123' }
  let(:stripe_email) { 'satoshi@example.com' } # Email as known by Stripe
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

  # Assuming the service method is now `call(session_id)`
  subject(:call_service) { described_class.call(session_id) }

  context 'when a user record exists matching the email from the Stripe session' do
    let!(:existing_user) do
      users(:satoshi)
    end

    before do
      # This context assumes stripe_email (satoshi@example.com) matches an existing user (users(:satoshi))
      expect(User.find_by(email: stripe_email)).to eq(existing_user), "Precondition failed: User with email '#{stripe_email}' should be users(:satoshi)."
    end

    it 'does not create a new user' do
      expect { call_service }.not_to change(User, :count)
    end

    it 'returns a success result with the existing user' do
      result = call_service
      expect(result).to be_success
      expect(result.payload).to eq(existing_user)
    end

    context 'when the existing user initially has no stripe_customer_id' do
      before do
        existing_user.update!(stripe_customer_id: nil)
      end

      it 'updates their stripe_customer_id with the one from the Stripe session' do
        expect { call_service }.to change { existing_user.reload.stripe_customer_id }
          .from(nil).to(stripe_customer_id)
      end
    end

    context 'when the existing user already has the correct stripe_customer_id' do
      before do
        existing_user.update!(stripe_customer_id: stripe_customer_id)
      end

      it 'does not change their stripe_customer_id' do
        expect { call_service }.not_to change { existing_user.reload.stripe_customer_id }
      end

      it 'still returns the existing user' do
        result = call_service
        expect(result.payload).to eq(existing_user)
      end
    end

    context 'when the existing user has a different, non-nil stripe_customer_id' do
      let(:old_stripe_id) { 'cus_old_id_12345' }
      before do
        existing_user.update!(stripe_customer_id: old_stripe_id)
      end

      it 'does not change their stripe_customer_id (service only updates if nil)' do
        expect { call_service }.not_to change { existing_user.reload.stripe_customer_id }
        expect(existing_user.reload.stripe_customer_id).to eq(old_stripe_id)
      end

      it 'still returns the existing user' do
        result = call_service
        expect(result.payload).to eq(existing_user)
      end
    end
  end

  context 'when no user record exists matching the email from the Stripe session' do
    # Override the email used by the mock Stripe session for this context
    let(:stripe_email) { 'nonexistent-user@example.com' }
    # Use a different stripe_customer_id for this non-existent user's session to avoid collision if needed
    let(:stripe_customer_id) { 'cus_new_non_existent_user' }

    before do
      # Ensure no user exists with this email for a clean test
      User.find_by(email: stripe_email)&.destroy
      expect(User.find_by(email: stripe_email)).to be_nil, "Precondition failed: User with email '#{stripe_email}' should not exist."
    end

    it 'does not create a new user' do
      expect { call_service }.not_to change(User, :count)
    end

    it 'returns a success result with a nil payload' do
      result = call_service
      expect(result).to be_success
      expect(result.payload).to be_nil
    end
  end
end
