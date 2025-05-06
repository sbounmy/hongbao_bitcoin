require 'rails_helper'

RSpec.describe Paper, type: :model do
  before do
    @bundle = bundles(:dollar)
    @bundle.input_items.create(input: inputs(:dollar))
    @paper = build(:paper, bundle: @bundle)
  end

  it 'sets elements from theme' do
    @paper.save!
    expect(@paper.elements).to eq(inputs(:dollar).ai)
    expect(@paper.elements.keys).to include("private_key_qrcode", "private_key_text", "public_address_qrcode", "public_address_text", "mnemonic_text","custom_text")
  end

  it 'sets elements from default elements when theme is not set' do
    @bundle.input_items.destroy_all
    @paper.save!
    expect(@paper.elements).to eq(Input::Theme.default_ai_elements)
    expect(@paper.elements.keys).to include("private_key_qrcode", "private_key_text", "public_address_qrcode", "public_address_text", "mnemonic_text")
  end


end
