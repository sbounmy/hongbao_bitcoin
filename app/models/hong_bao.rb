class HongBao < ApplicationRecord
  belongs_to :paper

  # encrypts :private_key

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paper_id, presence: true

  before_create :generate_bitcoin_keys, :generate_mt_pelerin_request

  store :mt_pelerin_response, accessors: [ :id, :amount, :currency, :address, :hash, :external_id ], prefix: true
  store :mt_pelerin_request, accessors: [ :hash, :code, :message ], prefix: true

  private

  def generate_bitcoin_keys
    key = Bitcoin::Key.generate
    self.public_key = key.pub
    self.private_key = key.priv
    self.address = key.addr
  end

  def generate_mt_pelerin_request
    begin
      self.mt_pelerin_request_code ||= rand(1000..9999).to_s
      message = "MtPelerin-#{mt_pelerin_request_code}"
      key = Bitcoin::Key.new(private_key)
      puts "key: #{key.priv.inspect}"
      signature = key.sign_message(message)
      self.mt_pelerin_request_hash = Base64.strict_encode64(signature)
    rescue => e
      Rails.logger.error "Mt Pelerin Hash Generation Error: #{e.class}"
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
