require 'rails_helper'

RSpec.describe 'Metadata concern integration' do
  describe Tag do
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

  describe Input::Event do
    it 'works with multiple metadata fields' do
      event = Input::Event.new(name: 'Test Event', date: '2025-01-01')
      event.description = 'Test description'
      event.price_usd = 100
      event.fixed_day = false
      
      expect(event.metadata).to include(
        'date' => '2025-01-01',
        'description' => 'Test description',
        'price_usd' => 100,
        'fixed_day' => false
      )
    end
  end

  describe Input::Theme do
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

  describe Paper do
    it 'works with metadata fields with suffix' do
      paper = Paper.new(name: 'Test Paper')
      
      # Set token counts
      paper.input_tokens = 100
      paper.output_tokens = 50
      paper.total_tokens = 150
      
      # Set costs
      paper.input_costs = 0.01
      paper.output_costs = 0.02
      paper.total_costs = 0.03
      
      expect(paper.metadata).to include(
        'tokens' => { 'input' => 100, 'output' => 50, 'total' => 150 },
        'costs' => { 'input' => 0.01, 'output' => 0.02, 'total' => 0.03 }
      )
    end
  end
end