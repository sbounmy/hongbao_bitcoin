# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessPaperJob, type: :job, vcr: { cassette_name: "process_paper_job", serialize_with: :compressed } do
  let(:message) { messages(:one) }


  it "creates paper on success" do
    expect { described_class.perform_now(message) }.to change(Paper, :count).by(1)
  end

  it 'saves tokens used' do
    described_class.perform_now(message)
    expect(message.input_tokens).to eq(589)
    expect(message.output_tokens).to eq(1056)
    expect(message.input_image_tokens).to eq(517)
    expect(message.input_text_tokens).to eq(72)
    expect(message.total_tokens).to eq(1645)

    expect(message.total_cost).to eq(0.04813) # dollar
    expect(message.input_cost).to eq(0.00589) # dollar
    expect(message.output_cost).to eq(0.04224) # dollar
  end
end
