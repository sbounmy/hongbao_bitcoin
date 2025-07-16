require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'works with simple metadata accessors' do
    tag = Tag.new(name: 'Test', slug: 'test')
    tag.color = '#ff0000'
    tag.icon = 'star'

    expect(tag.metadata).to eq({ 'color' => '#ff0000', 'icon' => 'star' })

    tag.save!
    tag.reload

    expect(tag.color).to eq('#ff0000')
    expect(tag.icon).to eq('star')
  end

  it 'supports multiple fields in one metadata call' do
    # Tag uses: metadata :color, :icon
    tag = Tag.new(name: 'Test2', slug: 'test2')
    expect(tag).to respond_to(:color)
    expect(tag).to respond_to(:icon)
  end
end
