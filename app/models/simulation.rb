# frozen_string_literal: true

class Simulation
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Configuration constants
  DEFAULT_YEARS = 5

  # Satoshi Nakamoto's birthday
  DEFAULT_BIRTHDAY = {
    month: 4,
    day: 5
  }.freeze

  DEFAULT_EVENT_COLOR = "#6b7280"

  # Gift equivalent visualization for stats cards
  # Each gift has a price threshold - you get the most expensive gift you can afford
  GIFT_EQUIVALENTS = [
    # Small amounts (< $100)
    { value: 0, label: "Coffee & Snacks", emoji: "☕", image_url: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80", category: "lifestyle" },
    { value: 20, label: "Nice Dinner", emoji: "🍽️", image_url: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80", category: "lifestyle" },
    { value: 50, label: "Concert Ticket", emoji: "🎫", image_url: "https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80", category: "experience" },

    # Consumer electronics (< $2k)
    { value: 100, label: "AirPods Pro", emoji: "🎧", image_url: "https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=800&q=80", category: "electronics" },
    { value: 300, label: "iPad", emoji: "📱", image_url: "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&q=80", category: "electronics" },
    { value: 600, label: "iPhone Pro", emoji: "📱", image_url: "https://images.unsplash.com/photo-1591337676887-a217a6970a8a?w=800&q=80", category: "electronics" },
    { value: 1200, label: "MacBook Air", emoji: "💻", image_url: "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80", category: "electronics" },

    # Mid-range ($2k-$15k)
    { value: 2500, label: "Gaming PC", emoji: "🖥️", image_url: "https://images.unsplash.com/photo-1593640495253-23196b27a87f?w=800&q=80", category: "electronics" },
    { value: 5000, label: "Motorcycle", emoji: "🏍️", image_url: "https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800&q=80", category: "vehicle" },
    { value: 10_000, label: "Toyota", emoji: "🚗", image_url: "https://images.unsplash.com/photo-1697316052164-6b832d49516c?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=800", category: "vehicle" },

    # Higher amounts ($20k-$100k)
    { value: 20_000, label: "Home Renovation", emoji: "🏗️", image_url: "https://images.unsplash.com/flagged/photo-1573168710465-7f7da9a23a15?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=800", category: "realestate" },
    { value: 35_000, label: "Tesla", emoji: "🏎️", image_url: "https://images.unsplash.com/photo-1606016159991-dfe4f2746ad5?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=800", category: "vehicle" },
    { value: 60_000, label: "Tiny House", emoji: "🛖", image_url: "https://plus.unsplash.com/premium_photo-1686090450574-214118216bdc?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=800", category: "realestate" },
    { value: 90_000, label: "College Tuition", emoji: "🎓", image_url: "https://images.unsplash.com/photo-1576049519901-ef17971aedc4?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=800", category: "education" },

    # Life-changing amounts ($100k+)
    { value: 100_000, label: "House Down Payment", emoji: "🏠", image_url: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800&q=80", category: "realestate" },
    { value: 200_000, label: "Small House", emoji: "🏡", image_url: "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80", category: "realestate" },
    { value: 500_000, label: "Family Home", emoji: "🏘️", image_url: "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80", category: "realestate" },
    { value: 1_000_000, label: "Dream House", emoji: "🏰", image_url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80", category: "realestate" },

    # Ultra-luxury ($5M+)
    { value: 5_000_000, label: "Yacht", emoji: "🛥️", image_url: "https://images.unsplash.com/photo-1567899378494-47b22a2ae96a?w=800&q=80", category: "luxury" },
    { value: 20_000_000, label: "Private Jet", emoji: "✈️", image_url: "https://images.unsplash.com/photo-1540962351504-03099e0a754b?w=800&q=80", category: "luxury" },
    { value: 50_000_000, label: "Private Island", emoji: "🏝️", image_url: "https://images.unsplash.com/photo-1516091877740-fde016699f2c?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=800", category: "luxury" }
  ].freeze

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

        month = opts[:birthday_month].to_i
        day = opts[:birthday_day].to_i

        # Handle invalid dates by capping to the last day of the month
        begin
          Date.new(year, month, day)
        rescue ArgumentError
          # If the day is invalid for the month, use the last day of that month
          last_day = Date.new(year, month, -1).day
          Date.new(year, month, [ day, last_day ].min)
        end
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
      description: "Varies (lunar calendar)",
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
      OpenStruct.new(id: 0, email: "simulation@hongbao.tc")
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
    EVENTS[event_key.to_sym]&.fetch(:color, DEFAULT_EVENT_COLOR) || DEFAULT_EVENT_COLOR
  end

  # Find the gift equivalent for a given dollar amount
  # Returns the most expensive gift you can afford with the given amount
  # @param amount [Numeric] The dollar amount to find an equivalent for
  # @return [Hash, nil] The matching gift equivalent or nil if amount is invalid
  def self.gift_equivalent_for(amount)
    return nil if amount.nil? || amount < 0
    # Find all gifts you can afford, then return the most expensive one
    GIFT_EQUIVALENTS.select { |gift| amount >= gift[:value] }
                    .max_by { |gift| gift[:value] }
  end

  # Get default parameters for simulation service (legacy compatibility)
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
