require 'rails_helper'

RSpec.describe Input::Theme, type: :model do
  it 'stores elements in dedicated column' do
    theme = Input::Theme.new(name: 'Test Theme', slug: 'test-theme')

    # Set elements
    theme.elements = { 'private_key_qrcode' => { 'x' => 10, 'y' => 20 } }

    expect(theme.elements).to include('private_key_qrcode' => { 'x' => 10, 'y' => 20 })
  end

  it 'provides default elements when none set' do
    theme = Input::Theme.new(name: 'Test Theme', slug: 'test-theme')

    expect(theme.elements).to eq(Input::Theme.default_elements)
    expect(theme.elements).to have_key('private_key_qrcode')
    expect(theme.elements).to have_key('portrait')
  end
end
