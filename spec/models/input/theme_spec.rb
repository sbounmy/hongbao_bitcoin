require 'rails_helper'

RSpec.describe Input::Theme, type: :model do
  it 'works with nested metadata accessors' do
    theme = Input::Theme.new(name: 'Test Theme', slug: 'test-theme')

    # Set UI properties
    theme.ui_name = 'dark'
    theme.ui_color_primary = '#ff0000'

    # Set AI properties
    theme.ai_name = 'custom'

    expect(theme.metadata).to have_key('ui')
    expect(theme.metadata).to have_key('ai')
    expect(theme.ui).to include('name' => 'dark', 'color_primary' => '#ff0000')
    expect(theme.ai).to include('name' => 'custom')
  end
end
