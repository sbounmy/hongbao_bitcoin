require 'rails_helper'

RSpec.describe Input, type: :model do
  subject { inputs(:dollar) }

   it 'can store metadata' do
    expect(subject.metadata).to include({
        "ui" => {
          "name" => "cyberpunk",
          "color_base_100" => "#e6f4f1",
          "color_primary" => "#006e8f",
          "radius_selector" => "1rem",
          "color_base_200" => "#ccecf2",
          "color_base_300" => "#00a8cc",
          "color_base_content" => "#112f4e",
          "color_primary_content" => "#ffffff",
          "color_secondary" => "#d83933",
          "color_secondary_content" => "#ffffff",
          "color_accent" => "#a3edeb",
          "color_accent_content" => "#112f4e",
          "depth" => "2"
        },
        "ai" => {
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
        }
      })
  end

  context 'for theme' do
    it 'is accessible as ui' do
      expect(subject.ui).to include({
        "name" => "cyberpunk",
        "color_base_100" => "#e6f4f1",
        "color_primary" => "#006e8f",
        "radius_selector" => "1rem",
        "color_base_200" => "#ccecf2",
        "color_base_300" => "#00a8cc",
        "color_base_content" => "#112f4e",
        "color_primary_content" => "#ffffff",
        "color_secondary" => "#d83933",
        "color_secondary_content" => "#ffffff",
        "color_accent" => "#a3edeb",
        "color_accent_content" => "#112f4e",
        "depth" => "2"
      })
    end

    it 'is accessible as ai' do
      expect(subject.ai).to include({
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

    it 'supports ui properties accessor' do
      expect {
        subject.update ui_color_primary: 'yellow'
      }.to change(subject, :ui_color_primary).from('#006e8f').to('yellow')

      expect(subject.ui).to include({
        "name" => "cyberpunk",
        "color_base_100" => "#e6f4f1",
        "color_primary" => "yellow",
        "radius_selector" => "1rem",
        "color_base_200" => "#ccecf2",
        "color_base_300" => "#00a8cc",
        "color_base_content" => "#112f4e",
        "color_primary_content" => "#ffffff",
        "color_secondary" => "#d83933",
        "color_secondary_content" => "#ffffff",
        "color_accent" => "#a3edeb",
        "color_accent_content" => "#112f4e",
        "depth" => "2"
      })
    end

    it 'supports ai properties accessor' do
      expect {
        subject.update ai_private_key_qrcode_x: "0.13"
      }.to change(subject, :ai_private_key_qrcode_x).from("10").to("0.13")

      expect(subject.ai).to include({
        "private_key_qrcode" => {
          "x" => "0.13",
          "y" => "37",
          "width" => "9.0",
          "height" => "18.0",
          "color" => "#000000",
          "type" => "private_key/qrcode",
          "side" => "back"
        }
      })
    end

    it 'is accessible by ui[...]' do
      expect(subject.ui_name).to eql('cyberpunk')
      expect(subject.ui['color_primary']).to eql('#006e8f')
    end

    it 'is accessible by ai[...]' do
      expect(subject.ai_private_key_qrcode_x).to eql("10")
    end
  end
end
