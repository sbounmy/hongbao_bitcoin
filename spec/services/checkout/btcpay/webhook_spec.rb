require 'rails_helper'

RSpec.describe Checkout::Btcpay::Webhook do
  fixtures :users, :orders, :tokens

  let(:service) { described_class }
  let(:webhook_secret) { "test_webhook_secret" }
  let(:payload) { event_data.to_json }
  let(:valid_signature) { "sha256=" + OpenSSL::HMAC.hexdigest("sha256", webhook_secret, payload) }
  let(:request) do
    instance_double(ActionDispatch::Request,
      body: StringIO.new(payload),
      env: { "HTTP_BTCPAY_SIG" => valid_signature }
    )
  end

  before do
    allow(Rails.application.credentials).to receive(:dig)
      .with(:btcpay, :webhook_secret)
      .and_return(webhook_secret)
  end

  describe '#call' do
    context 'when signature is missing' do
      let(:event_data) { { "type" => "InvoiceSettled" } }
      let(:request) do
        instance_double(ActionDispatch::Request,
          body: StringIO.new(payload),
          env: {}
        )
      end

      it 'raises error about missing header' do
        expect {
          service.call(request)
        }.to raise_error(RuntimeError, /BTCPaySig header is missing/)
      end
    end

    context 'when signature is invalid' do
      let(:event_data) { { "type" => "InvoiceSettled" } }
      let(:request) do
        instance_double(ActionDispatch::Request,
          body: StringIO.new(payload),
          env: { "HTTP_BTCPAY_SIG" => "sha256=invalid_signature" }
        )
      end

      it 'raises error about invalid signature' do
        expect {
          service.call(request)
        }.to raise_error(RuntimeError, /Webhook signature is invalid/)
      end
    end

    context 'when InvoiceReceivedPayment event' do
      let(:event_data) do
        {
          "type" => "InvoiceReceivedPayment",
          "invoiceId" => "btc_invoice_123",
          "metadata" => {
            "userId" => users(:john).id,
            "buyerEmail" => "john@example.com",
            "amount" => 25.0,
            "currency" => "EUR",
            "title" => "100 Tokens Package",
            "tokens" => 100,
            "envelopes" => 10,
            "description" => "Best value package",
            "color" => "orange",
            "redirectRef" => "ref123",
            "buyerName" => "John Doe",
            "buyerAddress1" => "123 Main St",
            "buyerAddress2" => "Apt 4B",
            "buyerCity" => "Paris",
            "buyerState" => "IDF",
            "buyerZip" => "75001",
            "buyerCountry" => "FR",
            "buyerPhone" => "+33612345678"
          }
        }
      end

      context 'with existing user' do
        it 'creates order for existing user' do
          expect {
            service.call(request)
          }.to change(Order, :count).by(1)
            .and change(LineItem, :count).by(1)

          order = Order.last
          expect(order).to have_attributes(
            user: users(:john),
            total_amount: 25.0,
            currency: "EUR",
            payment_provider: "btcpay",
            external_id: "btc_invoice_123",
            redirect_ref: "ref123",
            shipping_name: "John Doe",
            shipping_address_line1: "123 Main St",
            shipping_city: "Paris",
            shipping_country: "FR"
          )

          expect(order.line_items.first.metadata).to include(
            "tokens" => 100,
            "envelopes" => 10,
            "color" => "orange"
          )
        end

        it 'returns success with order' do
          result = service.call(request)
          expect(result).to be_success
          expect(result.payload).to be_a(Order)
        end
      end

      context 'with guest user (no userId)' do
        let(:event_data) do
          super().tap do |data|
            data["metadata"]["userId"] = nil
            data["metadata"]["buyerEmail"] = "newuser@example.com"
          end
        end

        it 'creates new user with random password' do
          expect {
            service.call(request)
          }.to change(User, :count).by(1)

          new_user = User.find_by(email: "newuser@example.com")
          expect(new_user).to be_present
          expect(new_user.authenticate("wrong_password")).to be_falsey
        end

        it 'creates order for new user' do
          expect {
            service.call(request)
          }.to change(Order, :count).by(1)

          order = Order.last
          expect(order.user.email).to eq("newuser@example.com")
        end
      end

      context 'when user creation fails' do
        let(:event_data) do
          super().tap do |data|
            data["metadata"]["userId"] = nil
            data["metadata"]["buyerEmail"] = "invalid-email"
          end
        end

        it 'raises validation error' do
          expect {
            service.call(request)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when InvoiceProcessing event' do
      let(:order) { orders(:pending_btcpay) }
      let(:event_data) do
        {
          "type" => "InvoiceProcessing",
          "invoiceId" => order.external_id
        }
      end

      it 'updates order status to processing' do
        expect(order.state).to eq("pending")

        service.call(request)

        order.reload
        expect(order.state).to eq("processing")
      end

      context 'when order not found' do
        let(:event_data) do
          super().merge("invoiceId" => "non_existent")
        end

        it 'raises error' do
          expect {
            service.call(request)
          }.to raise_error(RuntimeError, /Order not found/)
        end
      end
    end

    context 'when InvoiceSettled event' do
      let(:order) { orders(:processing_btcpay) }
      let(:event_data) do
        {
          "type" => "InvoiceSettled",
          "invoiceId" => order.external_id
        }
      end

      before do
        order.line_items.create!(
          quantity: 1,
          price: 25.0,
          metadata: {
            "tokens" => 100,
            "envelopes" => 10,
            "description" => "Test package",
            "color" => "orange"
          }
        )
      end

      it 'completes order and creates tokens' do
        expect {
          service.call(request)
        }.to change { order.reload.state }.from("processing").to("completed")
          .and change(Token, :count).by(1)

        token = Token.last
        expect(token).to have_attributes(
          user: order.user,
          quantity: 100,
          external_id: order.external_id,
          description: "Test package"
        )
        expect(token.metadata).to include(
          "envelopes" => 10,
          "color" => "orange"
        )
      end
    end

    context 'when InvoiceExpired event' do
      let(:order) { orders(:pending_btcpay) }
      let(:event_data) do
        {
          "type" => "InvoiceExpired",
          "invoiceId" => order.external_id
        }
      end

      it 'marks order as failed' do
        expect {
          service.call(request)
        }.to change { order.reload.state }.from("pending").to("failed")
      end
    end

    context 'with idempotency check' do
      let(:completed_order) { orders(:completed_btcpay) }
      let(:event_data) do
        {
          "type" => "InvoiceSettled",
          "invoiceId" => completed_order.external_id
        }
      end

      it 'does not process already completed order' do
        expect {
          result = service.call(request)
          expect(result).to be_success
          expect(result.payload).to eq("Order ##{completed_order.id} already processed")
        }.not_to change(Token, :count)
      end
    end

    context 'with unknown event type' do
      let(:event_data) do
        {
          "type" => "UnknownEventType",
          "invoiceId" => "some_id"
        }
      end

      it 'returns success without processing' do
        result = service.call(request)
        expect(result).to be_success
      end
    end
  end
end
