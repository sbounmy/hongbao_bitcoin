class SavedHongBao < ApplicationRecord
  include AASM

  belongs_to :user
  has_one_attached :file

  aasm column: "status", whiny_transitions: false do
    state :created, initial: true
    state :hodl
    state :withdrawn
    state :lost
    state :no_funds

    event :mark_hodl do
      transitions from: [ :created, :no_funds, :withdrawn, :lost ], to: :hodl
    end

    event :mark_withdrawn do
      transitions from: [ :created, :hodl, :no_funds, :lost ], to: :withdrawn
    end

    event :mark_lost do
      transitions from: [ :created, :hodl, :no_funds, :withdrawn ], to: :lost
    end

    event :mark_no_funds do
      transitions from: [ :created, :hodl ], to: :no_funds
    end
  end

  # Custom setter to handle status transitions
  def status=(new_status)
    return if new_status.blank? || aasm.current_state.to_s == new_status.to_s

    # Track when status changes
    status_was_changed = false

    case new_status.to_s
    when "hodl"
      status_was_changed = mark_hodl! if may_mark_hodl?
    when "withdrawn"
      status_was_changed = mark_withdrawn! if may_mark_withdrawn?
    when "lost"
      status_was_changed = mark_lost! if may_mark_lost?
    when "no_funds"
      status_was_changed = mark_no_funds! if may_mark_no_funds?
    when "created"
      # Allow direct assignment for created status (initial state)
      write_attribute(:status, new_status)
      status_was_changed = true
    end

    # Set the status_changed_at timestamp if status actually changed
    # Only set it automatically if it's not already being set by the form
    if status_was_changed && !status_changed_at_changed?
      self.status_changed_at = Time.current
    end
  end

  validates :name, presence: true
  validates :address, presence: true
  validates :address, uniqueness: { scope: :user_id, message: "has already been saved" }
  validate :valid_bitcoin_address
  validate :file_size_validation

  before_create :set_initial_status_changed_at
  after_create_commit :schedule_balance_refresh
  after_create_commit :broadcast_prepend_to_user
  after_update_commit :broadcast_replace_to_user

  scope :order_by_gifted_at, -> { order Arel.sql("COALESCE(gifted_at, created_at) DESC") }
  scope :needs_refresh, -> { where(status: [ "created", "hodl" ]).where("last_fetched_at IS NULL OR last_fetched_at < ?", 24.hours.ago) }

  belongs_to :spot_buy, class_name: "Spot", optional: true # set asynchronously

  def btc
    (current_sats || 0).to_f / 100_000_000
  end

  def usd
    (Spot.current(:usd).usd || 0) * btc
  end

  def initial_btc
    (initial_sats || 0).to_f / 100_000_000
  end

  def initial_usd
    initial_btc * (spot_buy&.usd || 0)
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

  # Legacy method for backward compatibility - checks if all funds have been withdrawn
  def withdrawn?
    current_sats == 0 && initial_sats && initial_sats > 0
  end

  # Check if balance hasn't changed from initial
  def untouched?
    initial_sats && current_sats && (initial_sats == current_sats)
  end

  def status_display
    case aasm.current_state
    when :created
      { icon: "clock", text: "CREATED", class: "badge-ghost" }
    when :withdrawn
      { icon: "check-circle", text: "WITHDRAWN", class: "text-success" }
    when :hodl
      { icon: "hand-thumb-up", text: "HODL", class: "text-warning" }
    when :no_funds
      { icon: "exclamation-triangle", text: "NO FUNDS", class: "text-error" }
    when :lost
      { icon: "exclamation-circle", text: "LOST", class: "text-error" }
    else
      { icon: "question-mark-circle", text: "UNKNOWN", class: "text-base-content/50" }
    end
  end

  def update_status_based_on_balance
    return if lost? # Don't override manual "lost" status

    if !initial_sats.to_i.zero? && current_sats.to_i.zero?
      mark_withdrawn! if may_mark_withdrawn?
    elsif !initial_sats.to_i.zero? && current_sats == initial_sats
      mark_hodl! if may_mark_hodl?
    elsif initial_sats.to_i.zero? && current_sats.to_i.zero?
      mark_no_funds! if may_mark_no_funds?
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

  def avatar_url
    "https://api.dicebear.com/9.x/open-peeps/svg?seed=#{ERB::Util.url_encode(name.downcase.strip)}&radius=50"
  end

  # Check if this hong bao should be included in portfolio calculations
  def active?
    created? || hodl?
  end

  def inactive?
    withdrawn? || lost? || no_funds?
  end

  private

  def set_initial_status_changed_at
    self.status_changed_at ||= Time.current
  end

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

  def file_size_validation
    return unless file.attached?

    if file.blob.byte_size > 10.megabytes
      errors.add(:file, "size should be less than 10MB")
    end
  end
end
