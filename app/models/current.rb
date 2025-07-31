class Current < ActiveSupport::CurrentAttributes
  attribute :session, :network
  delegate :user, to: :session, allow_nil: true

  def self.network_gem
    network == :mainnet ? :bitcoin : :testnet
  end

  def self.testnet?
    network == :testnet
  end

  TESTNET_ADDRESS_PREFIXES = %w[tb m n 2].freeze
  TESTNET_WIF_PREFIXES = %w[c 9].freeze

  def self.network_from_key(key)
    key_str = key.to_s

    testnet_address?(key_str) || testnet_wif?(key_str) ? :testnet : :mainnet
  end

  def self.testnet_address?(key_str)
    TESTNET_ADDRESS_PREFIXES.any? { |prefix| key_str.start_with?(prefix) }
  end

  def self.testnet_wif?(key_str)
    TESTNET_WIF_PREFIXES.any? { |prefix| key_str.start_with?(prefix) }
  end

  private_class_method :testnet_address?, :testnet_wif?
end
