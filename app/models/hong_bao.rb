class HongBao
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Define attributes
  attribute :paper_id, :integer
  attribute :public_key, :string
  attribute :private_key, :string
  attribute :address, :string
  attribute :mnemonic, :string
  attribute :seed, :string
  attribute :entropy, :string
  attribute :mt_pelerin_request_code, :string
  attribute :mt_pelerin_request_hash, :string

  validates :paper_id, presence: true

  # Initialize with bitcoin keys generation
  def initialize(attributes = {})
    super
    generate_bitcoin_keys
    generate_mt_pelerin_request
  end

  private

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
end
