require "test_helper"

class HongBaoTest < ActiveSupport::TestCase
  test "mt pelerin test vector" do
    # Create HongBao with test vector private key
    hong_bao = HongBao.new(
      paper: papers(:one),
      amount: 100
    )

    hong_bao.save!
    hong_bao.update(private_key: "4142e80a872531fd1055f52ccab713d4c7f1eee28c33415558e74faeb516de2b",
    mt_pelerin_request_code: "1234",
    address: "0x270402aeB8f4dAc8203915fC26F0768feA61b532")
    # Force the generation of the request
    hong_bao.send(:generate_mt_pelerin_request)


    # Assert test vector values
    assert_equal "0x270402aeB8f4dAc8203915fC26F0768feA61b532", hong_bao.address
    assert_equal "1234", hong_bao.mt_pelerin_request_code
    assert_equal "/37KcpG6mEp+1oAan8/HLEvcfZFXUi6kTOxTHNjD3ZloxS8DL70v7lCmXiEyDOATm4hvewMzBO2d1n25QdJ8WBw=",
                 hong_bao.mt_pelerin_request_hash
  end

  # test "mt pelerin test vector with seed phrase" do
  #   # Test the second vector from docs
  #   hong_bao = HongBao.new(
  #     paper: papers(:one),
  #     amount: 100,
  #     private_key: "78ba65f1cc9427fab632340ae4d705b1485fba9f73ab5a24816907d36d5729e9"
  #   )

  #   def hong_bao.generate_mt_pelerin_request
  #     self.mt_pelerin_request_code = "1234"
  #     message = "MtPelerin-#{mt_pelerin_request_code}"
  #     key = Bitcoin::Key.new(private_key, nil, false)
  #     signature = key.sign_message(message)
  #     self.mt_pelerin_request_hash = Base64.strict_encode64(signature)
  #   end

  #   hong_bao.send(:generate_mt_pelerin_request)

  #   assert_equal "0xEa22e16EA50A43092853329F3cEEa0825Cb9B03e", hong_bao.address
  #   assert_equal "1234", hong_bao.mt_pelerin_request_code
  #   assert_equal "yrXNJSmMc4wvVyKEzN4cEmLTvEaridjqTULZAfMwYAMM5PgBz4fCoIWNLr5NwKhxOYiPpI2vhMlKCihWadUw5xs=",
  #                hong_bao.mt_pelerin_request_hash
  # end
end
