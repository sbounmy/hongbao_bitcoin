require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#theme_css' do
    let(:theme) { inputs(:dollar) }

    it 'returns an empty string when no theme is provided' do
      expect(helper.theme_css(nil)).to eq('')
    end

    it 'generates CSS for theme properties' do
      css = helper.theme_css(theme)
      expect(css).to include('<style>')
      expect(css).to include('[data-theme="cyberpunk"]')
      expect(css).to include('--color-primary: red;')
      expect(css).to include('--depth: 2;')
      expect(css).to include('</style>')
    end

    it 'returns html_safe content' do
      css = helper.theme_css(theme)
      expect(css).to be_html_safe
    end

    it 'only includes properties that are present' do
      css = helper.theme_css(theme)
      expect(css).not_to include('--color-secondary')
    end
  end
end
