require 'rails_helper'

RSpec.describe Input, type: :model do
  subject { inputs(:dollar) }

  it 'can store metadata' do
    expect(subject.metadata).to include({
        ui: {
          name: "cyberpunk",
          color_primary: "red",
          depth: "2"
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
        color_primary: "red",
        depth: "2"
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
      }.to change(subject, :ui_color_primary).from('red').to('yellow')

      expect(subject.ui).to include({
        name: "cyberpunk",
        color_primary: "yellow",
        depth: "2"
      })
    end

    it 'supports ai properties accessor' do
      expect {
        subject.update ai_private_address_qrcode["x"]: 0.13
      }.to change(subject, :ai_private_address_qrcode["x"]).from(0.12).to(0.13)

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
      expect(subject.ui[:color_primary]).to eql('red')
    end

    it 'is accessible by ai[...]' do
      expect(subject.ai_private_address_qrcode["x"]).to eql(0.12)
    end
  end
end
