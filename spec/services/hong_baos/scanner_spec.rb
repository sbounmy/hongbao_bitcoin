require 'rails_helper'

RSpec.describe HongBaos::Scanner do
  let(:service) { described_class }

  before do
    # we disable error propagation for these tests because we are expecting failure responses
    described_class.propagate = false
  end

  describe '#call' do
    context 'when scanned key is blank' do
      it 'returns failure for nil input' do
        result = service.call(nil)

        expect(result).to be_failure
        expect(result.error).to be_a(HongBaos::Scanner::ScanError)
        expect(result.error.user_message).to eq("Invalid QR code")
      end

      it 'returns failure for empty string' do
        result = service.call("")

        expect(result).to be_failure
        expect(result.error).to be_a(HongBaos::Scanner::ScanError)
        expect(result.error.user_message).to eq("Invalid QR code")
      end
    end

    context 'when scanned key is a Bitcoin address' do
      context 'mainnet addresses' do
        before { Current.network = :mainnet }

        it 'handles P2PKH address (starts with 1)' do
          result = service.call("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")

          expect(result).to be_success
          expect(result.payload).to be_a(HongBao)
          expect(result.payload.address).to eq("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
          expect(result.payload.private_key).to be_nil
        end

        it 'handles P2SH address (starts with 3)' do
          result = service.call("3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy")

          expect(result).to be_success
          expect(result.payload.address).to eq("3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy")
        end

        it 'handles Bech32 address (starts with bc1)' do
          result = service.call("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq")

          expect(result).to be_success
          expect(result.payload.address).to eq("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq")
        end
      end

      context 'testnet addresses' do
        before { Current.network = :testnet }

        it 'handles testnet P2PKH address (starts with m/n)' do
          result = service.call("mxVFsFW5N4mu1HPkxPttorvocvzeZ7KZyk")

          expect(result).to be_success
          expect(result.payload.address).to eq("mxVFsFW5N4mu1HPkxPttorvocvzeZ7KZyk")
        end

        it 'handles testnet Bech32 address (starts with tb1)' do
          result = service.call("tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn")

          expect(result).to be_success
          expect(result.payload.address).to eq("tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn")
        end
      end
    end

    context 'when scanned key is a private key' do
      context 'WIF format private keys' do
        before { Current.network = :testnet }

        it 'handles compressed WIF (starts with c for testnet)' do
          wif_key = "cV1Y7ARUr9Yx7BR55nTdnR7ZXNJphZtCCMBTEZBJe1hXt2kB684q"
          result = service.call(wif_key)

          expect(result).to be_success
          expect(result.payload).to be_a(HongBao)
          expect(result.payload.private_key).to be_present
          expect(result.payload.private_key).to match(/^[0-9a-f]{64}$/i) # Should be hex
          expect(result.payload.public_key).to be_present
          expect(result.payload.address).to match(/^[mn]/) # testnet address
        end

        it 'handles uncompressed WIF (starts with 9 for testnet)' do
          # Testnet uncompressed WIF
          wif_key = "92Pg46rUhgTT7romnV7iGW6W1gbGdeezqdbJCzShkCsYNzyyNcc"
          result = service.call(wif_key)

          expect(result).to be_success
          expect(result.payload.private_key).to be_present
          expect(result.payload.address).to start_with('m').or start_with('n')
        end
      end

      context 'mainnet WIF format' do
        before { Current.network = :mainnet }

        it 'handles compressed mainnet WIF (starts with K/L)' do
          wif_key = "L1aW4aubDFB7yfras2S1mN3bqg9nwySY8nkoLmJebSLD5BWv3ENZ"
          result = service.call(wif_key)

          expect(result).to be_success
          expect(result.payload.address).to start_with('1') # mainnet P2PKH
        end
      end

      context 'hex format private keys' do
        before { Current.network = :testnet }

        it 'handles 64-character hex private key' do
          hex_key = "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35"
          result = service.call(hex_key)

          expect(result).to be_success
          expect(result.payload.private_key).to eq(hex_key)
          expect(result.payload.public_key).to be_present
          expect(result.payload.address).to be_present
        end
      end
    end

    context 'when scanned key is an app URL' do
      context 'with valid wallet URL' do
        before { Current.network = :mainnet }

        it 'extracts mainnet address from URL' do
          app_url = "https://hongbao.bitcoin/addrs/1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
          result = service.call(app_url)

          expect(result).to be_success
          expect(result.payload).to be_a(HongBao)
          expect(result.payload.address).to eq("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
        end

        it 'extracts testnet address from URL' do
          Current.network = :testnet
          app_url = "https://hbtc.me/a/tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn"
          result = service.call(app_url)

          expect(result).to be_success
          expect(result.payload.address).to eq("tb1q8f5smkw6hdd47mauz9lq2ffezl9szmxrk342xn")
        end
      end

      context 'with invalid URL format' do
        it 'returns failure with user-friendly message' do
          invalid_url = "https://example.com/not-a-wallet"
          result = service.call(invalid_url)

          expect(result).to be_failure
          expect(result.error).to be_a(HongBaos::Scanner::ScanError)
          expect(result.error.user_message).to eq("This QR code contains a URL that is not a Bitcoin wallet")
        end
      end
    end

    context 'when invalid inputs are provided' do
      before { Current.network = :testnet }

      it 'returns failure for random text' do
        result = service.call("xdxdxd")

        expect(result).to be_failure
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to include("Private key must be a valid hexadecimal string")
      end

      it 'returns failure for invalid hex length' do
        result = service.call("deadbeef") # Too short

        expect(result).to be_failure
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to include("Private key must be exactly 64 hex characters")
      end

      it 'returns failure for invalid WIF format' do
        result = service.call("KDOUDOUDODUODUOUDOUDOU")

        expect(result).to be_failure
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to include("Private key must be a valid hexadecimal string")
      end

      it 'returns failure for invalid address' do
        result = service.call("1InvalidAddress")

        expect(result).to be_failure
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to include("Private key must be a valid hexadecimal string")
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
