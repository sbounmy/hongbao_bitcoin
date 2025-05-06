require 'rails_helper'

RSpec.describe Paper, type: :model do
  before do
    @bundle = bundles(:one)
    @bundle.input_items.create(input: themes(:dollar))
    @paper = create(:paper, bundle: @bundle)
  end

  it 'sets default elements from theme' do
    expect(@paper.elements).to eq({ "x" => 0.12, "y" => 0.38, "size" => 0.17, "color" => "224, 120, 1", "max_text_width" => 100 })
  end

  it 'fails when has no theme' do
    bundle = bundles(:one)
    bundle.input_items.create(input: themes(:dollar))
    expect {
      create(:paper, bundle: bundle)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end


end
