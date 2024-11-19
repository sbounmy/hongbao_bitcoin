# bitcoin.rb

Bitcoin.network = if Rails.env.production?
  :bitcoin
else
  :testnet
end

    module Bitcoin
      module Util
        def bitcoin_elliptic_curve
          ::OpenSSL::PKey::EC.generate("secp256k1")
        end

        def generate_key
          key = bitcoin_elliptic_curve
          inspect_key(key)
        end
      end

      class Key
        def generate
          @key
        end
      end
    end
