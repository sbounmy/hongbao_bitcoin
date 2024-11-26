class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP }

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
end
