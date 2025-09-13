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
            "size" => "9",
            "color" => "#000000",
            "max_text_width" => ""
          },
          "private_key_text" => {
            "x" => "9",
            "y" => "57",
            "size" => "8",
            "color" => "#000000",
            "max_text_width" => "12"
          },
          "public_address_qrcode" => {
            "x" => "22",
            "y" => "24",
            "size" => "9",
            "color" => "",
            "max_text_width" => ""
          },
          "public_address_text" => {
            "x" => "21",
            "y" => "55",
            "size" => "8",
            "color" => "#000000",
            "max_text_width" => "12"
          },
          "mnemonic_text" => {
            "x" => "5",
            "y" => "50",
            "size" => "13",
            "color" => "#000000",
            "max_text_width" => "400"
          },
          "custom_text" => {
            "x" => "",
            "y" => "",
            "size" => "",
            "color" => "",
            "max_text_width" => ""
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
          "size" => "9",
          "color" => "#000000",
          "max_text_width" => ""
        },
        "private_key_text" => {
          "x" => "9",
          "y" => "57",
          "size" => "8",
          "color" => "#000000",
          "max_text_width" => "12"
        },
        "public_address_qrcode" => {
          "x" => "22",
          "y" => "24",
          "size" => "9",
          "color" => "",
          "max_text_width" => ""
        },
        "public_address_text" => {
          "x" => "21",
          "y" => "55",
          "size" => "8",
          "color" => "#000000",
          "max_text_width" => "12"
        },
        "mnemonic_text" => {
          "x" => "5",
          "y" => "50",
          "size" => "13",
          "color" => "#000000",
          "max_text_width" => "400"
        },
        "custom_text" => {
          "x" => "",
          "y" => "",
          "size" => "",
          "color" => "",
          "max_text_width" => ""
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
          "size" => "9",
          "color" => "#000000",
          "max_text_width" => ""
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
