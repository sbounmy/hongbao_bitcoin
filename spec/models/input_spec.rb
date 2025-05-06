require 'rails_helper'

RSpec.describe Input, type: :model do
  subject { inputs(:dollar) }

  it 'can store metadata' do
    expect(subject.metadata).to include({
        ui: {
          name: "cyberpunk",
          color_base_100: "#e6f4f1",
          color_primary: "#006e8f",
          radius_selector: "1rem",
          color_base_200: "#ccecf2",
          color_base_300: "#00a8cc",
          color_base_content: "#112f4e",
          color_primary_content: "#ffffff",
          color_secondary: "#d83933",
          color_secondary_content: "#ffffff",
          color_accent: "#a3edeb",
          color_accent_content: "#112f4e"
        },
        ai: {
          private_address_qrcode: {
            x: 0.12,
            y: 0.38,
            size: 0.17,
            color: "224, 120, 1",
            max_text_width: 100
          },
          private_address_text: {
            x: 0.12,
            y: 0.38,
            size: 0.17,
            color: "224, 120, 1",
            max_text_width: 100
          },
          public_address_qrcode: {
            x: 0.12,
            y: 0.38,
            size: 0.17,
            color: "224, 120, 1",
            max_text_width: 100
          },
          public_address_text: {
            x: 0.12,
            y: 0.38,
            size: 0.17,
            color: "224, 120, 1",
            max_text_width: 100
          },
          mnemonic_text: {
            x: 0.12,
            y: 0.38,
            size: 0.17,
            color: "224, 120, 1",
            max_text_width: 100
          }
        }
      })
  end

  context 'for theme' do
    it 'is accessible as ui' do
      expect(subject.ui).to include({
        name: "cyberpunk",
        color_base_100: "#e6f4f1",
        color_primary: "#006e8f",
        radius_selector: "1rem",
        color_base_200: "#ccecf2",
        color_base_300: "#00a8cc",
        color_base_content: "#112f4e",
        color_primary_content: "#ffffff",
        color_secondary: "#d83933",
        color_secondary_content: "#ffffff",
        color_accent: "#a3edeb",
        color_accent_content: "#112f4e",
        depth: 2
      })
    end

    it 'is accessible as ai' do
      expect(subject.ai).to include({
        private_address_qrcode: {
          x: 0.12,
          y: 0.38,
          size: 0.17,
          color: "224, 120, 1",
          max_text_width: 100
        },
        private_address_text: {
          x: 0.12,
          y: 0.38,
          size: 0.17,
          color: "224, 120, 1",
          max_text_width: 100
        },
        public_address_qrcode: {
          x: 0.12,
          y: 0.38,
          size: 0.17,
          color: "224, 120, 1",
          max_text_width: 100
        },
        public_address_text: {
          x: 0.12,
          y: 0.38,
          size: 0.17,
          color: "224, 120, 1",
          max_text_width: 100
        },
        mnemonic_text: {
          x: 0.12,
          y: 0.38,
          size: 0.17,
          color: "224, 120, 1",
          max_text_width: 100
        }
      })
    end

    it 'supports ui properties accessor' do
      expect {
        subject.update ui_color_primary: 'yellow'
      }.to change(subject, :ui_color_primary).from('#006e8f').to('yellow')

      expect(subject.ui).to include({
        name: "cyberpunk",
        color_base_100: "#e6f4f1",
        color_primary: "yellow",
        radius_selector: "1rem",
        color_base_200: "#ccecf2",
        color_base_300: "#00a8cc",
        color_base_content: "#112f4e",
        color_primary_content: "#ffffff",
        color_secondary: "#d83933",
        color_secondary_content: "#ffffff",
        color_accent: "#a3edeb",
        color_accent_content: "#112f4e",
        depth: 2
      })
    end

    it 'supports ai properties accessor' do
      expect {
        subject.update ai_private_address_qrcode_x: 0.13
      }.to change(subject, :ai_private_address_qrcode_x).from(0.12).to(0.13)

      expect(subject.ai).to include({
        private_address_qrcode: {
          x: 0.13,
          y: 0.38,
          size: 0.17,
          color: "224, 120, 1",
          max_text_width: 100
        }
      })
    end

    it 'is accessible by ui[...]' do
      expect(subject.ui_name).to eql('cyberpunk')
      expect(subject.ui[:color_primary]).to eql('#006e8f')
    end

    it 'is accessible by ai[...]' do
      expect(subject.ai_private_address_qrcode["x"]).to eql(0.12)
    end
  end
end
