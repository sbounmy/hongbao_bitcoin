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
      expect(css).to include('--color-primary: #006e8f;')
      expect(css).to include('--color-base-100: #e6f4f1;')
      expect(css).to include('--color-base-200: #ccecf2;')
      expect(css).to include('--color-base-300: #00a8cc;')
      expect(css).to include('--color-base-content: #112f4e;')
      expect(css).to include('--color-primary-content: #ffffff;')
      expect(css).to include('--color-secondary: #d83933;')
      expect(css).to include('--color-secondary-content: #ffffff;')
      expect(css).to include('--color-accent: #a3edeb;')
      expect(css).to include('--color-accent-content: #112f4e;')
      expect(css).to include('--radius-selector: 1rem;')
      expect(css).to include('--depth: 2;')
      expect(css).to include('</style>')
    end

    it 'returns html_safe content' do
      css = helper.theme_css(theme)
      expect(css).to be_html_safe
    end

    it 'only includes properties that are present' do
      css = helper.theme_css(theme)
      expect(css).not_to include('--color-error')
    end
  end
end
