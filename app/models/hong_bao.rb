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

  def self.generate(paper_id:)
    hong_bao = new(paper_id: paper_id)
    hong_bao.generate_bitcoin_keys
    hong_bao.generate_mt_pelerin_request
    hong_bao
  end

  def self.from_scan(key)
    hong_bao = new(scanned_key: key, paper_id: 0)
    hong_bao
  end

  def generate_bitcoin_keys
    master = Bitcoin::Master.generate
    self.public_key = master.key.pub
    self.private_key = master.key.to_base58
    self.address = master.key.addr
    self.mnemonic = master.mnemonic
    self.seed = master.seed
    self.entropy = master.entropy
  end

  def generate_mt_pelerin_request
    self.mt_pelerin_request_code = rand(1000..9999).to_s
    message = "MtPelerin-#{mt_pelerin_request_code}"

    bitcoin_key = Bitcoin::Key.new(Bitcoin::Key.from_base58(private_key).priv, public_key)
    self.mt_pelerin_request_hash = bitcoin_key.sign_message(message)
  end

  def scanned_key=(key)
    Bitcoin.network = :bitcoin # beucase I tested a bill topped up with mt pelerin
    if Bitcoin.valid_address?(key)
      self.address = key
    else
      self.private_key = Bitcoin::Key.from_base58(key)
      self.public_key = self.private_key.pub
      self.address = self.private_key.addr
    end
  end

  def balance
    @balance ||= Balance.fetch_for_address(address)
  end
end
