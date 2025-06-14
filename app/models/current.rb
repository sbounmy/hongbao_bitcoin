class Current < ActiveSupport::CurrentAttributes
  attribute :session, :network
  delegate :user, to: :session, allow_nil: true

  def self.network_gem
    network == :mainnet ? :bitcoin : :testnet
  end

  def self.testnet?
    network == :testnet
  end
end
