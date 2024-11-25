class Paper < ApplicationRecord
  has_many_attached :images
  has_many :hong_baos

  validates :name, presence: true
  validates :images, presence: true
  validates :style, presence: true

  enum :style, {
    classic: 0,
    modern: 1,
    lunar: 2
  }

  scope :active, -> { where(active: true).order(position: :asc) }

  ELEMENTS = [
    :qrcode_private_key,
    :qrcode_private_key_label,
    :qrcode_public_key,
    :qrcode_public_key_label,
    :private_key_address,
    :private_key_address_label,
    :public_key_address,
    :public_key_address_label,
    :amount,
    :amount_btc
  ]

  store :elements, coder: JSON

  # Define accessors for each element with coordinates
  ELEMENTS.each do |element|
    define_method(element) do
      elements&.dig(element.to_s)
    end

    define_method("#{element}=") do |value|
      self.elements ||= {}
      self.elements[element.to_s] = value.is_a?(Hash) ? value : { "x" => 0, "y" => 0, "size" => 0 }
    end
  end

  after_initialize :set_default_elements, if: :new_record?

  private

  def set_default_elements
    self.elements ||= {
      "qrcode_private_key" => {
        "x" => 100,
        "y" => 100,
        "size" => 150,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "qrcode_private_key_label" => {
        "x" => 100,
        "y" => 260,
        "size" => 12,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "qrcode_public_key" => {
        "x" => 300,
        "y" => 100,
        "size" => 150,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "qrcode_public_key_label" => {
        "x" => 300,
        "y" => 260,
        "size" => 12,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "private_key_address" => {
        "x" => 100,
        "y" => 300,
        "size" => 10,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "private_key_address_label" => {
        "x" => 100,
        "y" => 320,
        "size" => 12,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "public_key_address" => {
        "x" => 300,
        "y" => 300,
        "size" => 10,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "public_key_address_label" => {
        "x" => 300,
        "y" => 320,
        "size" => 12,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "amount" => {
        "x" => 200,
        "y" => 400,
        "size" => 24,
        "color" => "#fff",
        "opacity" => "0.25"
      },
      "amount_btc" => {
        "x" => 200,
        "y" => 430,
        "size" => 18,
        "color" => "#fff",
        "opacity" => "0.25"
      }
    }
  end
end
