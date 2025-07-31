require 'rails_helper'

RSpec.describe HongBaos::Scanner do
  let(:service) { described_class }

  describe '#call' do
    context 'when scanned key is blank' do
      it 'raises a ScanError' do
        expect {
          service.call(nil)
        }.to raise_error(HongBaos::Scanner::ScanError) do |error|
          expect(error.user_message).to eq("Invalid QR code")
        end
      end

      it 'raises a ScanError for empty string' do
        expect {
          service.call("")
        }.to raise_error(HongBaos::Scanner::ScanError) do |error|
          expect(error.user_message).to eq("Invalid QR code")
        end
      end
    end

    context 'when scanned key is a Bitcoin address' do
      let(:bitcoin_address) { "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" }

      before do
        allow(Current).to receive(:network_gem).and_return(:bitcoin)
      end

      it 'creates a HongBao with the address' do
        # Use call! to get the result directly (without Response wrapper)
        result = service.call!(bitcoin_address)

        expect(result).to be_success
        expect(result.payload).to be_a(HongBao)
        expect(result.payload.address).to eq(bitcoin_address)
      end
    end

    context 'when scanned key is a private key' do
      let(:private_key) { "5JaTXbAUmfPYZFRwrYaALK48fN6sFJp4rHqq2QSXs8ucfpE4yQU" }
      let(:expected_address) { "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" }

      before do
        allow(Current).to receive(:network_gem).and_return(:bitcoin)
        # Mock Bitcoin::Key to return expected values
        mock_key = instance_double(Bitcoin::Key,
          priv: private_key,
          pub: "mock_public_key",
          addr: expected_address
        )
        allow(Bitcoin::Key).to receive(:new).with(private_key).and_return(mock_key)
      end

      it 'creates a HongBao containing private key' do
        # Use call! to get the result directly
        result = service.call!(private_key)

        expect(result).to be_success
        expect(result.payload).to be_a(HongBao)
        expect(result.payload.private_key).to eq(private_key)
        expect(result.payload.address).to eq(expected_address)
      end
    end

    context 'when scanned key is an app URL' do
      context 'with valid wallet URL' do
        let(:app_url) { "https://hongbao.bitcoin/addrs/1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" }
        let(:bitcoin_address) { "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" }

        before do
          allow(Current).to receive(:network_gem).and_return(:bitcoin)
        end

        it 'extracts the address and creates HongBao' do
          result = service.call!(app_url)

          expect(result).to be_success
          expect(result.payload).to be_a(HongBao)
          expect(result.payload.address).to eq(bitcoin_address)
        end
      end

      context 'with invalid URL format' do
        let(:invalid_url) { "https://example.com/not-a-wallet" }

        it 'raises a ScanError with user-friendly message' do
          expect {
            service.call(invalid_url)
          }.to raise_error(HongBaos::Scanner::ScanError) do |error|
            expect(error.user_message).to eq("This QR code contains a URL that is not a Bitcoin wallet")
          end
        end
      end
    end

    context 'when HongBao.from_scan returns invalid result' do
      let(:invalid_key) { "not-a-valid-key" }

      before do
        allow(Current).to receive(:network_gem).and_return(:bitcoin)
        allow(Bitcoin).to receive(:valid_address?).with(invalid_key).and_return(false)
        # Mock Bitcoin::Key to raise error for invalid key
        allow(Bitcoin::Key).to receive(:new).with(invalid_key).and_raise(RuntimeError, "Invalid key")
      end

      it 'raises the error' do
        expect {
          service.call(invalid_key)
        }.to raise_error(RuntimeError, "Invalid key")
      end
    end

    context 'when unexpected error occurs' do
      let(:scanned_key) { "test-key" }

      before do
        allow(HongBao).to receive(:from_scan).and_raise(StandardError, "Unexpected error")
      end

      it 'raises the original error' do
        expect {
          service.call(scanned_key)
        }.to raise_error(StandardError, "Unexpected error")
      end
    end
  end

  describe 'HongBaos::Scanner::ScanError' do
    it 'stores user_message when provided' do
      error = HongBaos::Scanner::ScanError.new("Technical message", user_message: "User friendly message")

      expect(error.message).to eq("Technical message")
      expect(error.user_message).to eq("User friendly message")
    end

    it 'uses main message as user_message when not provided' do
      error = HongBaos::Scanner::ScanError.new("Error message")

      expect(error.message).to eq("Error message")
      expect(error.user_message).to eq("Error message")
    end
  end
end
