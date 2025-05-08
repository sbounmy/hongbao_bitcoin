# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessPaperJob, type: :job, vcr: { cassette_name: "process_paper_job", serialize_with: :compressed } do
  let(:message) { messages(:one) }
  let(:paper) { papers(:dollar) }

  before do
    paper.image_front.purge
    paper.image_back.purge
    paper.save!
  end

  it "updates paper front on success" do
    expect { described_class.perform_now(message) }.to change { Paper.last.image_front.attached? }.from(false).to(true)
  end

  it "updates paper back on success" do
    expect { described_class.perform_now(message) }.to change { Paper.last.image_back.attached? }.from(false).to(true)
  end

  it 'updates paper full on success' do
    # expect { described_class.perform_now(message) }.to change { Paper.last.image_full.attached? }.from(false).to(true)
    described_class.perform_now(message)
    expect(Paper.last.image_full.attached?).to be_truthy
  end

  it 'saves tokens used' do
    described_class.perform_now(message)
    message.reload
    expect(message.input_tokens).to eq(589)
    expect(message.output_tokens).to eq(1056)
    expect(message.input_image_tokens).to eq(517)
    expect(message.input_text_tokens).to eq(72)
    expect(message.total_tokens).to eq(1645)

    expect(message.total_costs).to eq(0.04813) # dollar
    expect(message.input_costs).to eq(0.00589) # dollar
    expect(message.output_costs).to eq(0.04224) # dollar
  end
end
