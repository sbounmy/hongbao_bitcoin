require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'can set tokens' do
    messages(:one).update input_tokens: 100,
                          output_tokens: 400,
                          input_text_tokens: 100,
                          input_image_tokens: 100,
                          total_tokens: 200,
                          input_costs: 10,
                          output_costs: 40,
                          total_costs: 50
    messages(:one).reload
    expect(messages(:one).input_tokens).to eq(100)
    expect(messages(:one).output_tokens).to eq(400)
    expect(messages(:one).input_text_tokens).to eq(100)
    expect(messages(:one).input_image_tokens).to eq(100)
    expect(messages(:one).total_tokens).to eq(200)
    expect(messages(:one).input_costs).to eq(10)
    expect(messages(:one).output_costs).to eq(40)
    expect(messages(:one).total_costs).to eq(50)
  end
end
