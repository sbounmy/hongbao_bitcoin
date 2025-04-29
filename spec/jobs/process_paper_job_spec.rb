# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessPaperJob, type: :job do
  let(:message) { messages(:one) }


  it "creates paper on success", vcr: { cassette_name: "process_paper_job", serialize_with: :compressed } do
    expect { described_class.perform_now(message) }.to change(Paper, :count).by(1)
  end
end
