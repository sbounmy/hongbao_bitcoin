# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessPaperJob, type: :job, vcr: { cassette_name: "process_paper_job", serialize_with: :compressed } do
  let(:paper) { papers(:dollar) }

  before do
    paper.image_front.purge
    paper.image_back.purge
    paper.save!
  end

  it "updates paper front on success" do
    expect { described_class.perform_now(paper.id) }.to change { paper.reload.image_front.attached? }.from(false).to(true)
  end

  it "updates paper back on success" do
    expect { described_class.perform_now(paper.id) }.to change { paper.reload.image_back.attached? }.from(false).to(true)
  end

  it 'attaches portrait image on success' do
    described_class.perform_now(paper.id)
    expect(paper.reload.image_portrait.attached?).to be_truthy
  end

  it 'saves tokens used' do
    described_class.perform_now(paper.id)
    paper.reload
    expect(paper.input_tokens).to eq(589)
    expect(paper.output_tokens).to eq(1056)
    expect(paper.input_image_tokens).to eq(517)
    expect(paper.input_text_tokens).to eq(72)
    expect(paper.total_tokens).to eq(1645)

    expect(paper.total_costs).to eq(0.04813) # dollar
    expect(paper.input_costs).to eq(0.00589) # dollar
    expect(paper.output_costs).to eq(0.04224) # dollar
  end

  it 'uses theme back image if available' do
    described_class.perform_now(paper.id)
    puts paper.image_front.attached?.inspect
    puts paper.image_back.attached?.inspect
    paper.save!
    expect(paper.reload.image_back.blob).to eq(active_storage_blobs(:dollar_theme_back_blob))
  end

  context "with None style (free)" do
    let(:paper) { papers(:none_style) }

    before do
      paper.image_front.purge
      paper.image_back.purge
      paper.image_portrait.purge if paper.image_portrait.attached?
      paper.save!
    end

    it "does not call Papers::StyleGenerator" do
      expect(Papers::StyleGenerator).not_to receive(:call)
      described_class.perform_now(paper.id)
    end

    it "uses original uploaded image as portrait" do
      described_class.perform_now(paper.id)
      expect(paper.reload.image_portrait.attached?).to be_truthy
    end

    it "still attaches front and back images" do
      described_class.perform_now(paper.id)
      paper.reload
      expect(paper.image_front.attached?).to be_truthy
      expect(paper.image_back.attached?).to be_truthy
    end

    it "does not track AI costs" do
      described_class.perform_now(paper.id)
      paper.reload
      expect(paper.total_tokens).to be_nil
      expect(paper.total_costs).to be_nil
    end
  end
end
