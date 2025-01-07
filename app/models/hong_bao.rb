class HongBao
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Existing attributes for generation
  attribute :paper_id, :integer
  attribute :public_key, :string
  attribute :private_key, :string
  attribute :address, :string
  attribute :mnemonic, :string
  attribute :seed, :string
  attribute :entropy, :string
  attribute :mt_pelerin_request_code, :string
  attribute :mt_pelerin_request_hash, :string

  # New attributes for scanning/transfer
  attribute :balance, :decimal
  attribute :to_address, :string
  attribute :amount, :decimal
  attribute :scanned_key, :string # For storing scanned public/private key

  validates :paper_id, presence: true
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true


  def self.from_scan(key)
    hong_bao = new(scanned_key: key, paper_id: 0)
    hong_bao
  end

  def scanned_key=(key)
    Bitcoin.network = :bitcoin # beucase I tested a bill topped up with mt pelerin
    if Bitcoin.valid_address?(key)
      self.address = key
    else
      # self.private_key = Bitcoin::Key.from_base58(key)
      pkey = Bitcoin::Key.new(key)
      self.private_key = pkey.priv
      self.public_key = pkey.pub
      self.address = pkey.addr
    end
  end

  def balance
    @balance ||= Balance.fetch_for_address(address)
  end

  def can_transfer?
    private_key.present?
  end

  def broadcast_transaction(signed_transaction)
    client = BlockCypher::Api.new(api_token: Rails.application.credentials.dig(:blockcypher, :token))
    response = client.push_tx(hex: signed_transaction)

    Rails.logger.info "Transaction broadcast response: #{response.inspect}"
    response["tx"]["hash"].present?
  rescue StandardError => e
    Rails.logger.error "Failed to broadcast transaction: #{e.message}"
    errors.add(:base, "Failed to broadcast transaction: #{e.message}")
    false
  end
end
