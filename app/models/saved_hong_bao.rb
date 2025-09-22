class SavedHongBao < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :address, presence: true
  validates :address, uniqueness: { scope: :user_id, message: "has already been saved" }
  validate :valid_bitcoin_address

  after_create_commit :schedule_balance_refresh
  after_create_commit :broadcast_prepend_to_user
  after_update_commit :broadcast_replace_to_user

  def btc
    (current_sats || 0).to_f / 100_000_000
  end

  def usd
    (current_spot || 0) * btc
  end

  def initial_btc
    (initial_sats || 0).to_f / 100_000_000
  end

  def initial_usd
    initial_btc * (initial_spot || 0)
  end

  def balance_change
    (current_sats || 0) - (initial_sats || 0)
  end

  def balance_change_percentage
    return 0 if initial_usd == 0
    ((usd_change / initial_usd) * 100).round(2)
  end

  def usd_change
    usd - initial_usd
  end

  def withdrawn?
    current_sats.to_i.zero?
  end

  def untouched?
    current_sats == initial_sats
  end

  def status
    if withdrawn?
      { icon: "arrow-down", text: "withdrawn", class: "text-error" }
    elsif untouched?
      { icon: "hand-thumb-up", text: "HODL", class: "text-warning" }
    else
      { icon: "arrow-trending-up", text: "increased", class: "text-success" }
    end
  end

  def needs_refresh?
    last_fetched_at.nil? || last_fetched_at < 1.hour.ago
  end

  def schedule_balance_refresh
    RefreshSavedHongBaoBalanceJob.perform_later(id)
  end

  def refresh_balance
    save!
  end

  # For backward compatibility with views/controllers
  def balance
    Current.network = Current.network_from_key(address)
    @balance ||= Balance.new(address: address)
  end


  private

  def broadcast_prepend_to_user
    broadcast_prepend_to(
      "user_#{user_id}_saved_hong_baos",
      target: "saved_hong_baos_table",
      renderable: SavedHongBaos::ItemComponent.new(saved_hong_bao: self, view_type: :table)
    )

    broadcast_prepend_to(
      "user_#{user_id}_saved_hong_baos",
      target: "saved_hong_baos_cards",
      renderable: SavedHongBaos::ItemComponent.new(saved_hong_bao: self, view_type: :card)
    )
  end

  def broadcast_replace_to_user
    broadcast_replace_to(
      "user_#{user_id}_saved_hong_baos",
      target: "saved_hong_bao_#{id}",
      renderable: SavedHongBaos::ItemComponent.new(saved_hong_bao: self, view_type: :table)
    )

    broadcast_replace_to(
      "user_#{user_id}_saved_hong_baos",
      target: "saved_hong_bao_card_#{id}",
      renderable: SavedHongBaos::ItemComponent.new(saved_hong_bao: self, view_type: :card)
    )
  end

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
end
