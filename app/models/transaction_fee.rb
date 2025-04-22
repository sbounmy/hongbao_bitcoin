class TransactionFee < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validate :presence_of_priorities

  def self.current
    order(date: :desc).first
  end

  def priority_options
    [
      { name: "Fast", satoshis: priorities["fast"], minutes: 10, amount: calculate_fee(priorities["fast"]) },
      { name: "Normal", satoshis: priorities["hour"], minutes: 120, amount: calculate_fee(priorities["hour"]), default: true },
      { name: "Slow", satoshis: priorities["minimum"], minutes: 1440, amount: calculate_fee(priorities["minimum"]) }
    ]
  end

  private

  def presence_of_priorities
    required_keys = %w[fast half_hour hour eco minimum]

    # Check if all required keys exist
    missing_keys = required_keys - priorities.keys
    if missing_keys.any?
      errors.add(:priorities, "missing required keys: #{missing_keys.join(', ')}")
      nil
    end
  end

  def calculate_fee(satoshis)
    # Assuming a typical transaction size of 250 bytes
    # This should be adjusted based on your actual transaction size calculation
    total_satoshis = satoshis * 250
    total_satoshis.to_f / Balance::SATOSHIS_PER_BTC # Convert to BTC
  end
end
