require 'rails_helper'

RSpec.describe Metadata, type: :concern do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :metadata_test_records, force: true do |t|
        t.string :name
        t.string :slug
        t.json :metadata, default: "{}"
        t.timestamps
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :metadata_test_records if table_exists?(:metadata_test_records)
    end
  end

  # Create a test class for each test case to avoid pollution
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'metadata_test_records'
      include Metadata
    end
  end

  describe '.metadata' do
    context 'with simple accessor' do
      before do
        test_class.metadata :color
        test_class.metadata :icon
      end

      it 'creates getter and setter methods' do
        instance = test_class.new
        expect(instance).to respond_to(:color)
        expect(instance).to respond_to(:color=)
        expect(instance).to respond_to(:icon)
        expect(instance).to respond_to(:icon=)
      end

      it 'stores values in metadata hash' do
        instance = test_class.new
        instance.color = '#ff0000'
        instance.icon = 'star'

        expect(instance.metadata).to eq({ 'color' => '#ff0000', 'icon' => 'star' })
      end

      it 'persists values to database' do
        instance = test_class.create!(name: 'test', slug: 'test')
        instance.color = '#00ff00'
        instance.icon = 'heart'
        instance.save!

        reloaded = test_class.find(instance.id)
        expect(reloaded.color).to eq('#00ff00')
        expect(reloaded.icon).to eq('heart')
      end

      it 'can query values from database' do
        instance = test_class.create!(name: 'test', slug: 'test')
        instance.color = '#00ff00'
        instance.icon = 'heart'
        instance.save!

        reloaded = test_class.where("json_extract(metadata, '$.color') = ?", '#00ff00').first
        expect(reloaded.color).to eq('#00ff00')
        expect(reloaded.icon).to eq('heart')
        reloaded = test_class.where("json_extract(metadata, '$.color') = ?", '#00000').first
        expect(reloaded).to be_nil
      end

      it 'handles nil values' do
        instance = test_class.new
        instance.color = nil
        expect(instance.color).to be_nil
        # Rails store doesn't save nil values by default
        expect(instance.metadata).to eq({})
      end
    end

    context 'with multiple simple accessors in one call' do
      before do
        test_class.metadata :date, :description, :price_usd, :fixed_day
      end

      it 'creates getter and setter methods for all fields' do
        instance = test_class.new
        expect(instance).to respond_to(:date)
        expect(instance).to respond_to(:date=)
        expect(instance).to respond_to(:description)
        expect(instance).to respond_to(:description=)
        expect(instance).to respond_to(:price_usd)
        expect(instance).to respond_to(:price_usd=)
        expect(instance).to respond_to(:fixed_day)
        expect(instance).to respond_to(:fixed_day=)
      end

      it 'stores all values in metadata hash' do
        instance = test_class.new
        instance.date = '2024-01-01'
        instance.description = 'Test event'
        instance.price_usd = 100
        instance.fixed_day = true

        expect(instance.metadata).to eq({
          'date' => '2024-01-01',
          'description' => 'Test event',
          'price_usd' => 100,
          'fixed_day' => true
        })
      end
    end

    context 'with nested accessors' do
      before do
        test_class.metadata :settings, accessors: [ :theme, :language, :timezone ]
      end

      it 'creates nested store' do
        instance = test_class.new
        expect(instance).to respond_to(:settings)
        expect(instance).to respond_to(:settings=)
      end

      it 'creates accessor methods for nested fields' do
        instance = test_class.new
        instance.settings = { theme: 'dark', language: 'en', timezone: 'UTC' }

        expect(instance.theme).to eq('dark')
        expect(instance.language).to eq('en')
        expect(instance.timezone).to eq('UTC')
      end

      it 'allows setting nested values individually' do
        instance = test_class.new
        instance.theme = 'light'
        instance.language = 'fr'

        expect(instance.settings).to eq({ 'theme' => 'light', 'language' => 'fr' })
      end
    end

    context 'with suffix option' do
      before do
        test_class.metadata :costs, accessors: [ :input, :output, :total ], suffix: true
      end

      it 'creates suffixed accessor methods' do
        instance = test_class.new
        expect(instance).to respond_to(:input_costs)
        expect(instance).to respond_to(:input_costs=)
        expect(instance).to respond_to(:output_costs)
        expect(instance).to respond_to(:output_costs=)
        expect(instance).to respond_to(:total_costs)
        expect(instance).to respond_to(:total_costs=)
      end

      it 'stores values in nested hash' do
        instance = test_class.new
        instance.input_costs = 10
        instance.output_costs = 20
        instance.total_costs = 30

        expect(instance.costs).to eq({ 'input' => 10, 'output' => 20, 'total' => 30 })
      end
    end

    context 'with prefix option' do
      before do
        test_class.metadata :ui, accessors: [ :color, :font, :size ], prefix: true
      end

      it 'creates prefixed accessor methods' do
        instance = test_class.new
        expect(instance).to respond_to(:ui_color)
        expect(instance).to respond_to(:ui_color=)
        expect(instance).to respond_to(:ui_font)
        expect(instance).to respond_to(:ui_font=)
        expect(instance).to respond_to(:ui_size)
        expect(instance).to respond_to(:ui_size=)
      end

      it 'stores values in nested hash' do
        instance = test_class.new
        instance.ui_color = 'blue'
        instance.ui_font = 'Arial'
        instance.ui_size = '16px'

        expect(instance.ui).to eq({ 'color' => 'blue', 'font' => 'Arial', 'size' => '16px' })
      end
    end

    context 'with multiple metadata declarations' do
      before do
        test_class.metadata :color
        test_class.metadata :settings, accessors: [ :theme, :language ]
        test_class.metadata :costs, accessors: [ :input, :output ], suffix: true
      end

      it 'handles all metadata fields correctly' do
        instance = test_class.new
        instance.color = 'red'
        instance.theme = 'dark'
        instance.language = 'en'
        instance.input_costs = 5
        instance.output_costs = 10

        expect(instance.metadata).to eq({
          'color' => 'red',
          'settings' => { 'theme' => 'dark', 'language' => 'en' },
          'costs' => { 'input' => 5, 'output' => 10 }
        })
      end
    end

    context 'initialization' do
      it 'initializes store when included' do
        # Store is initialized when the concern is included
        instance = test_class.new
        expect(instance).to respond_to(:metadata)
        expect(instance.metadata).to be_a(Hash)
      end
    end

    context 'with store options' do
      it 'supports all store options through metadata concern' do
        # The metadata concern should pass through all store options
        test_class.metadata :prefs, accessors: [ :locale, :timezone ]

        instance = test_class.new
        instance.locale = 'en'
        instance.timezone = 'UTC'
        expect(instance.locale).to eq('en')
        expect(instance.timezone).to eq('UTC')

        instance.locale = 'fr'
        expect(instance.prefs).to eq({ 'locale' => 'fr', 'timezone' => 'UTC' })
      end
    end
  end

  describe 'inheritance' do
    let(:parent_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'metadata_test_records'
        include Metadata
        metadata :parent_field
      end
    end

    let(:child_class) do
      Class.new(parent_class) do
        metadata :child_field
      end
    end

    it 'inherits parent metadata fields' do
      instance = child_class.new
      expect(instance).to respond_to(:parent_field)
      expect(instance).to respond_to(:child_field)
    end

    it 'stores all fields in the same metadata hash' do
      instance = child_class.new
      instance.parent_field = 'parent_value'
      instance.child_field = 'child_value'

      expect(instance.metadata).to eq({
        'parent_field' => 'parent_value',
        'child_field' => 'child_value'
      })
    end
  end
end
