require 'rails_helper'

RSpec.describe Input, type: :model do
  subject { inputs(:dollar) }

  context 'for theme' do
    it 'is accessible as elements' do
      expect(subject.elements).to include({
        "private_key_qrcode" => {
            "x" => "10",
            "y" => "37",
            "width" => "9.0",
            "height" => "18.0",
            "color" => "#000000",
            "type" => "private_key/qrcode",
            "side" => "back"
          },
        "private_key_text" => {
            "x" => "9",
            "y" => "57",
            "width" => "",
            "height" => "10",
            "size" => "1.8",
            "color" => "#000000",
            "type" => "private_key/text",
            "side" => "back"
          },
        "public_address_qrcode" => {
            "x" => "22",
            "y" => "24",
            "width" => "9.0",
            "height" => "18.0",
            "color" => "",
            "type" => "public_address/qrcode",
            "side" => "front"
          },
        "public_address_text" => {
            "x" => "21",
            "y" => "55",
            "width" => "",
            "height" => "10",
            "size" => "1.8",
            "color" => "#000000",
            "type" => "public_address/text",
            "side" => "front"
          },
        "mnemonic_text" => {
            "x" => "5",
            "y" => "50",
            "width" => "",
            "height" => "15",
            "size" => "1.6",
            "color" => "#000000",
            "type" => "mnemonic/text",
            "side" => "back"
          },
        "custom_text" => {
            "x" => "",
            "y" => "",
            "width" => "",
            "height" => "",
            "size" => "",
            "color" => "",
            "type" => "text",
            "side" => "back"
          },
        "portrait" => {
            "x" => "50",
            "y" => "60",
            "width" => 18,
            "height" => 36,
            "type" => "image",
            "side" => "front"
          }
      })
    end
  end
end
