class HongBao < ApplicationRecord
  belongs_to :paper

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paper_id, presence: true

  before_create :generate_bitcoin_keys, :generate_mt_pelerin_request

  # Store JSON fields for Mt Pelerin API responses and requests
  store :mt_pelerin_response, accessors: [ :id, :amount, :currency, :address, :hash, :external_id ], prefix: true
  store :mt_pelerin_request, accessors: [ :hash, :code, :message ], prefix: true

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

  private

  # Generates a new Bitcoin keypair and stores it
  # Called before create as part of before_create callback
  def generate_bitcoin_keys
    key = Bitcoin::Key.generate
    self.public_key = key.pub
    self.private_key = key.priv
    self.address = key.addr
  end

  # Generates Mt Pelerin request signature
  # Creates a random 4-digit code and signs "MtPelerin-{code}" message
  # Called before create as part of before_create callback
  def generate_mt_pelerin_request
    self.mt_pelerin_request_code ||= rand(1000..9999).to_s
    message = "MtPelerin-#{mt_pelerin_request_code}"

    # Sign the message using OpenSSL EC key
    key = pkey_from_private_key(private_key)
    signature = key.dsa_sign_asn1(message)
    self.mt_pelerin_request_hash = Base64.strict_encode64(signature)
  end

  # Creates an OpenSSL EC key from a private key
  # @param priv [String] Private key in hex format
  # @return [OpenSSL::PKey::EC] EC key ready for signing
  def pkey_from_private_key(priv)
    # Get corresponding public key
    pub = restore_public_key priv

    group = OpenSSL::PKey::EC::Group.new(CURVE)

    # Convert keys to OpenSSL big numbers
    private_key_bn   = OpenSSL::BN.new(priv, 16)
    public_key_bn    = OpenSSL::BN.new(pub, 16)
    public_key_point = OpenSSL::PKey::EC::Point.new(group, public_key_bn)

    # Create ASN1 structure for the key
    asn1 = OpenSSL::ASN1::Sequence(
      [
        OpenSSL::ASN1::Integer.new(1),                    # Version
        OpenSSL::ASN1::OctetString(private_key_bn.to_s(2)), # Private key
        OpenSSL::ASN1::ObjectId(CURVE, 0, :EXPLICIT),     # Curve identifier
        OpenSSL::ASN1::BitString(                         # Public key
          public_key_point.to_octet_string(:uncompressed),
          1,
          :EXPLICIT
        )
      ]
    )

    # Create EC key from ASN1 DER encoding
    OpenSSL::PKey::EC.new(asn1.to_der)
  end

  # Calculates public key from private key using EC multiplication
  # @param priv [String] Private key in hex format
  # @return [String] Public key in hex format
  def restore_public_key(priv)
    # Convert private key to big number
    private_bn = OpenSSL::BN.new priv, 16
    group = OpenSSL::PKey::EC::Group.new CURVE

    # Multiply generator point by private key to get public key point
    public_bn = group.generator.mul(private_bn).to_bn
    # Convert point to compressed format
    public_bn = OpenSSL::PKey::EC::Point.new(group, public_bn).to_bn

    public_bn.to_s(16).downcase
  end
end
