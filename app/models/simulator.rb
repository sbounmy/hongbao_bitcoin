# frozen_string_literal: true

class Simulator
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Configuration constants
  DEFAULT_YEARS = 5

  # Satoshi Nakamoto's birthday
  DEFAULT_BIRTHDAY = {
    month: 4,
    day: 5
  }.freeze

  # Merged event configuration with all details
  EVENTS = {
    christmas: {
      key: :christmas,
      label: "Christmas",
      emoji: "🎄",
      description: "December 25th",
      default_amount: 50,
      color: "#dc2626",
      calculate_date: ->(year, _opts) { Date.new(year, 12, 25) }
    },
    birthday: {
      key: :birthday,
      label: "Birthday",
      emoji: "🎂",
      description: "Satoshi's Birthday (April 5th)",
      default_amount: 100,
      color: "#ec4899",
      calculate_date: ->(year, opts) {
        return nil unless opts[:birthday_month] && opts[:birthday_day]
        Date.new(year, opts[:birthday_month], opts[:birthday_day])
      }
    },
    new_year: {
      key: :new_year,
      label: "New Year",
      emoji: "🎊",
      description: "January 1st",
      default_amount: 50,
      color: "#f59e0b",
      calculate_date: ->(year, _opts) { Date.new(year, 1, 1) }
    },
    chinese_new_year: {
      key: :chinese_new_year,
      label: "Chinese New Year",
      emoji: "🧧",
      description: "Varies by year (lunar calendar)",
      default_amount: 0,
      color: "#ef4444",
      calculate_date: ->(year, _opts) { ChineseNewYearService.for_year(year) }
    }
  }.freeze

  # EventHongBao struct for simulated events
  EventHongBao = Struct.new(
    :gifted_at,
    :initial_sats,
    :current_sats,
    :initial_usd,
    :name,
    :event_type,
    :event_emoji,
    :event_color,
    :spot_buy,
    keyword_init: true
  ) do
    def user
      OpenStruct.new(id: 0, email: "simulator@hongbao.tc")
    end

    def btc
      (current_sats || 0).to_f / 100_000_000
    end

    def initial_btc
      (initial_sats || 0).to_f / 100_000_000
    end

    # Compatibility methods for polymorphism with SavedHongBao
    def id; nil; end
    def address; nil; end
    def avatar_url; nil; end
    def status; { text: "simulated" }; end
  end

  # Form attributes
  attribute :years, :integer, default: DEFAULT_YEARS
  attr_accessor :events_attributes

  def initialize(params = {})
    super
    @events_attributes ||= build_default_events_attributes
  end

  # Transform form params to service params
  def to_service_params
    result = {
      years: years,
      events: [],
      event_amounts: {},
      birthday_month: DEFAULT_BIRTHDAY[:month],
      birthday_day: DEFAULT_BIRTHDAY[:day],
      currency: :usd
    }

    return result unless events_attributes

    events_attributes.each do |event_key, attrs|
      next unless attrs
      amount = attrs[:amount].to_f
      next if amount <= 0

      result[:events] << event_key.to_sym
      result[:event_amounts][event_key.to_sym] = amount

      if event_key.to_s == "birthday" && attrs[:month].present? && attrs[:day].present?
        result[:birthday_month] = attrs[:month].to_i
        result[:birthday_day] = attrs[:day].to_i
      end
    end

    result
  end

  # Class methods for event management
  def self.event_config(event_key)
    EVENTS[event_key.to_sym]
  end

  def self.calculate_event_date(event_key, year, opts = {})
    config = EVENTS[event_key.to_sym]
    return nil unless config
    config[:calculate_date].call(year, opts)
  end

  def self.event_color(event_key)
    EVENTS[event_key.to_sym]&.fetch(:color, "#6b7280")
  end

  # Get default parameters for simulator service (legacy compatibility)
  def self.default_params
    new.to_service_params
  end

  private

  def build_default_events_attributes
    EVENTS.transform_values do |config|
      {
        amount: config[:default_amount],
        month: (DEFAULT_BIRTHDAY[:month] if config[:key] == :birthday),
        day: (DEFAULT_BIRTHDAY[:day] if config[:key] == :birthday)
      }.compact
    end.transform_keys(&:to_s)
  end
end
