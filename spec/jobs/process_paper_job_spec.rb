# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessPaperJob, type: :job do
  let(:chat) { chats(:dollar_ghibli) }

  it "processes the paper", vcr: { cassette_name: "process_paper_job", serialize_with: :compressed } do
    expect { described_class.perform_now(chat) }.to change(Paper, :count).by(1)
  end
end
