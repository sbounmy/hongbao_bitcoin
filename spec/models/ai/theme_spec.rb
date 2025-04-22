require 'rails_helper'

RSpec.describe Ai::Theme, type: :model do
  # Load fixtures for this test suite
  fixtures 'ai/themes'

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:path) }
    it { should validate_uniqueness_of(:path) }
  end

  describe 'associations' do
    it { should have_and_belong_to_many(:elements) }
    it { should have_one_attached(:hero_image) }
  end

  describe 'ui accessors' do
    let(:theme) { ai_themes(:dollar) }

    it 'returns the ui_name' do
      expect(theme.ui_name).to eq('cyberpunk')
    end

    it 'returns a default ui_name when nil' do
      theme_instance = ai_themes(:dollar)
      theme_instance.ui_name = nil
      expect(theme_instance).to be_invalid
    end
  end

  describe '#set_default_path' do
    it 'sets the path from the title' do
      theme = build(:ai_theme, title: 'My Custom Theme', path: nil)
      theme.valid?
      expect(theme.path).to eq('my-custom-theme')
    end

    it 'does not override existing path' do
      theme = build(:ai_theme, title: 'My Custom Theme', path: 'existing-path')
      theme.valid?
      expect(theme.path).to eq('existing-path')
    end
  end

  describe '#theme_property' do
    let(:theme) { ai_themes(:dollar) }

    it 'returns the value for a property' do
      expect(theme.theme_property('color_primary')).to eq('red')
      expect(theme.theme_property('depth')).to eq('2')
    end

    it 'returns nil for missing properties' do
      expect(theme.theme_property('color-secondary')).to be_nil
    end
  end
end
