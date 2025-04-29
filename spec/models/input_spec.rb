require 'rails_helper'

RSpec.describe Input, type: :model do
  subject { inputs(:dollar) }

  it 'can store metadata' do
    expect(subject.metadata).to include({
        ui: {
          name: "cyberpunk",
          color_primary: "red",
          depth: "2"
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

    it 'is accessible by ui[...]' do
      expect(subject.ui_name).to eql('cyberpunk')
      expect(subject.ui[:color_primary]).to eql('red')
    end
  end
end
