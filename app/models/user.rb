require "ostruct"

class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :papers, dependent: :destroy
  has_many :tokens, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :bundles, dependent: :destroy
  has_many :saved_hong_baos, dependent: :destroy
  has_secure_password
  has_one_attached :avatar

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  after_create :add_tokens

  def add_tokens
    tokens.create(quantity: 5, description: "Welcome tokens")
  end

  def generate_magic_link
    update(
      magic_link_token: SecureRandom.urlsafe_base64,
      magic_link_expires_at: 30.minutes.from_now
    )
  end

  def valid_magic_link?(token)
    magic_link_token.present? &&
    magic_link_token == token &&
    magic_link_expires_at > Time.current
  end

  def clear_magic_link!
    update(magic_link_token: nil, magic_link_expires_at: nil)
  end

  def followers_count
    papers.count
  end

  def handle
    email.split("@").first
  end

  def self.fake(options = {})
    OpenStruct.new(options)
  end
end
