require "test_helper"

class HongBaoTest < ActiveSupport::TestCase
  def pkey_from_public_key(public_key)
    group = OpenSSL::PKey::EC::Group.new("secp256k1")

    public_key_bn    = OpenSSL::BN.new(public_key, 16)
    public_key_point = OpenSSL::PKey::EC::Point.new(group, public_key_bn)

    puts "public_key_bn: #{public_key_bn}"
    puts "public_key_point: #{public_key_point}"
    asn1 = OpenSSL::ASN1::Sequence.new(
      [
        OpenSSL::ASN1::Sequence.new([
                                      OpenSSL::ASN1::ObjectId.new("id-ecPublicKey"),
                                      OpenSSL::ASN1::ObjectId.new(group.curve_name)
                                    ]),
        OpenSSL::ASN1::BitString.new(public_key_point.to_octet_string(:uncompressed))
      ]
    )
    OpenSSL::PKey::EC.new(asn1.to_der)
  end

  test "mt pelerin test vector" do
    # Create HongBao with test vector private key
    hong_bao = HongBao.new(
      paper: papers(:one),
      amount: 100
    )

    hong_bao.save!
    hong_bao.update(private_key: "bb24dd9a24ca0e8386e6ca88d85b4a4e12c563fe261c5b926e28c5033b83132c",
    mt_pelerin_request_code: "1234",
    address: "mmjHdJR2ViT3way1HNFkWNuxt2rkXNJDAm")
    # Force the generation of the request
    hong_bao.send(:generate_mt_pelerin_request)


    # Assert test vector values
    # assert_equal "0x270402aeB8f4dAc8203915fC26F0768feA61b532", hong_bao.address
    assert_equal "1234", hong_bao.mt_pelerin_request_code
  # assert_equal "MEUCIBxkej/pR81suQwMG0gZ4LLAbaUdHqaVcQwmysr3HhJEAiEA0x+BF52yvQcEXA2IK9SN53M/OWhxoTZ0lUoLUSwa0eg=",
  #              hong_bao.mt_pelerin_request_hash


  key = pkey_from_public_key("04e3dc626382d3d4a3e882264e2234f9536580ffd3ce568d89fe270ef0032bb7a0bf0afa1ae8bde72c44c27de12eaad8fddbc08f87832a2c4051888f0504a74bcf")
    res = key.dsa_verify_asn1("MtPelerin-1234", Base64.decode64(hong_bao.mt_pelerin_request_hash))
    assert res, "Signature verification failed"
  end
end
