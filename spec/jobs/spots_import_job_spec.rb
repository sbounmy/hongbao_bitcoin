require 'rails_helper'
RSpec.describe SpotsImportJob, type: :job, vcr: true do
  describe "#perform" do
    before do
      SavedHongBao.destroy_all
      Spot.destroy_all # remove fixtures
      Timecop.freeze(Date.new(2013, 9, 1))
    end

    context "when seed is true" do
      it "imports daily prices until beginning of bitcoin history" do
        expect {
          described_class.new.perform("usd", seed: true)
        }.to change { Spot.count }.by(1143)
      end

      it 'prices import should be continous dates' do
        described_class.new.perform("usd", seed: true)

        spots = Spot.order(:date).pluck(:date)

        # Check that we have spots
        expect(spots).not_to be_empty

        # Check for continuous dates - each date should be 1 day after the previous
        spots.each_cons(2) do |prev_date, next_date|
          expect(next_date).to eq(prev_date + 1.day), "Gap found between #{prev_date} and #{next_date}"
        end
      end
    end

    context "when seed is false" do
      it "imports daily prices on last 11 days" do
        expect {
          described_class.new.perform
        }.to change { Spot.count }.by(11)
        expect(Spot.last).to have_attributes(
          date: Date.new(2013, 9, 1),
          prices: { 'usd' => 146.01 })
      end

      it 'update currency with existing spots' do
        described_class.new.perform

        expect {
          described_class.new.perform("eur")
        }.to_not change { Spot.count }

        expect(Spot.last).to have_attributes(
          date: Date.new(2013, 9, 1),
          prices: { 'usd' => 146.01, 'eur' => 108.36 })
      end
    end

    after do
      Timecop.return
    end
  end
end
