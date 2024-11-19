# bitcoin.rb

Bitcoin.network = if Rails.env.production?
  :bitcoin
else
  :testnet
end

module Bitcoin
  def bitcoin_elliptic_curve
    group = OpenSSL::PKey::EC::Group.new("secp256k1")
    OpenSSL::PKey::EC.new(group)
  end

  module Util
    def bitcoin_elliptic_curve
      group = OpenSSL::PKey::EC::Group.new("secp256k1")
      key = OpenSSL::PKey::EC.new(group)
      key.generate_key
      key
    end

    def generate_key
      key = bitcoin_elliptic_curve
      inspect_key(key)
    end
  end
end
