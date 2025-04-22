class PaperElement
  class Coder
    def self.dump(elements)
      return if elements.nil?

      elements.map(&:to_h).to_json
    end

    def self.load(json)
      return [] if json.nil?

      JSON.parse(json).map { |element_hash| PaperElement.new(element_hash) }
    end
  end

  include ActiveModel::Model
  include ActiveModel::Attributes

  VALID_NAMES = %w[
    qrcode_private_key
    private_key
    qrcode_public_key
    public_key_address
    mnemonic
    custom_text
  ].freeze

  attribute :name, :string
  attribute :x, :float
  attribute :y, :float
  attribute :size, :float
  attribute :color, :string

  validates :name, presence: true, inclusion: { in: VALID_NAMES }
  validates :x, :y, :size, presence: true, numericality: true
  validates :color, presence: true

  def to_h
    attributes.compact
  end
end
