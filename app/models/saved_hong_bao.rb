class SavedHongBao < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :address, presence: true
  validates :address, uniqueness: { scope: :user_id, message: "has already been saved" }
  validate :valid_bitcoin_address

  before_create :set_initial_data

  def balance
    Current.network = Current.network_from_key(address)
    @balance ||= Balance.new(address: address)
  end

  def satoshis
    balance.satoshis
  end

  def btc
    satoshis.to_f / 100_000_000
  end

  def usd
    satoshis.to_f / 100_000_000 * Spot.new.to(:usd)
  end

  def withdrawn?
    satoshis < initial_balance
  end

  def untouched?
    satoshis == initial_balance
  end

  def balance_change
    satoshis - initial_balance
  end

  def balance_change_percentage
    # Calculate percentage based on USD values for more accurate representation
    return 0 if initial_usd.nil? || initial_usd == 0
    ((usd_change / initial_usd) * 100).round(2)
  end

  def usd_change
    return 0 if initial_usd.nil?
    usd - initial_usd
  end

  def status
    if withdrawn?
      { icon: "arrow-down", text: "withdrawn", class: "text-error" }
    elsif untouched?
      { icon: "clock", text: "untouched", class: "text-warning" }
    else
      { icon: "arrow-trending-up", text: "increased", class: "text-success" }
    end
  end

  private

  def valid_bitcoin_address
    return if address.blank?

    # Basic Bitcoin address validation
    # Supports both Mainnet and Testnet addresses:
    # - Legacy (1, m, n)
    # - SegWit (3, 2)
    # - Native SegWit (bc1, tb1)
    unless address.match?(/\A(?:[13][a-km-zA-HJ-NP-Z1-9]{25,34}|[mn2][a-km-zA-HJ-NP-Z1-9]{25,34}|(?:bc|tb)1[a-zA-HJ-NP-Z0-9]{25,39})\z/)
      errors.add(:address, "is not a valid Bitcoin address")
    end
  end

  def set_initial_data
    # Fetch balance and transaction data once during creation
    balance_obj = Balance.new(address: address)

    # Set initial balance in satoshis
    self.initial_balance = balance_obj.satoshis

    # Set gifted_at from first transaction timestamp, or current time if no transactions
    first_transaction = balance_obj.transactions.first
    self.gifted_at ||= first_transaction&.timestamp

    # Set initial USD value using Spot price at the gifted date
    if initial_balance > 0 && gifted_at
      btc_amount = initial_balance.to_f / 100_000_000
      spot_price = Spot.new(date: gifted_at).to(:usd)
      self.initial_usd = (btc_amount * spot_price).round(2) if spot_price
    end
  end
end
