class HongBao < ApplicationRecord
  include AASM

  belongs_to :paper
  belongs_to :payment_method

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paper_id, presence: true
  validates :payment_method_id, presence: true

  # Store JSON fields for Mt Pelerin API responses and requests
  store :mt_pelerin_response, accessors: [ :id, :amount, :currency, :address, :hash, :external_id ], prefix: true
  store :mt_pelerin_request, accessors: [ :hash, :code, :message ], prefix: true

  after_initialize :generate_bitcoin_keys, if: :new_record?
  after_initialize :generate_mt_pelerin_request, if: :new_record?
  # Elliptic curve used by Bitcoin
  CURVE = "secp256k1"

  # Converts a public key to a Bitcoin address
  # @return [String] Bitcoin address in base58check format
  def bitcoin_address
    # Convert public key to hash160 (RIPEMD160(SHA256(public_key)))
    hash160 = Bitcoin.hash160([ public_key ].pack("H*"))
    # Encode with version byte to get final Bitcoin address
    Bitcoin.encode_address(hash160, Bitcoin.network[:pubkey_version])
  end

  def save_private_key=(value)
    if value == "0"
      self.private_key = nil
      self.mnemonic = nil
      self.seed = nil
      self.entropy = nil
    end
  end

  aasm column: :state do
    state :pending, initial: true
    state :paid
    state :failed
    state :expired

    event :pay do
      transitions from: :pending, to: :paid

      after do
        # Add any after-transition logic here
        # For example: notify user, trigger other processes, etc.
      end
    end

    event :fail do
      transitions from: :pending, to: :failed
    end

    event :expire do
      transitions from: :pending, to: :expired
    end
  end

  # Add encryption for sensitive fields
  encrypts :mnemonic, :private_key, :seed, :entropy

  # Validate uniqueness of seed
  validates :mnemonic, :private_key, :seed, :entropy, uniqueness: true, allow_nil: true

  private

  # Generates a new Bitcoin keypair
  def generate_bitcoin_keys
    master = Bitcoin::Master.generate
    self.public_key = master.key.pub
    self.private_key = master.key.to_base58
    self.address = master.key.addr
    self.mnemonic = master.mnemonic
    self.seed = master.seed
    self.entropy = master.entropy
  end

  # Generates Mt Pelerin request signature
  # Creates a random 4-digit code and signs "MtPelerin-{code}" message
  # Called before create as part of before_create callback
  def generate_mt_pelerin_request
    self.mt_pelerin_request_code ||= rand(1000..9999).to_s
    message = "MtPelerin-#{mt_pelerin_request_code}"

    bitcoin_key = Bitcoin::Key.new(Bitcoin::Key.from_base58(private_key).priv, public_key)
    signature = bitcoin_key.sign_message(message)
    self.mt_pelerin_request_hash = signature
  end
end
