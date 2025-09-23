require 'rails_helper'

RSpec.describe RefreshSavedHongBaoBalanceJob, type: :job do
  fixtures :users, :saved_hong_baos

  let(:saved_hong_bao) { saved_hong_baos(:created) }

  describe "#perform", vcr: { cassette_name: "refresh_saved_hong_bao_balance_job" } do
    it "updates the saved hong bao with current balance information" do
      Timecop.freeze(Time.utc(2025, 6, 22, 03)) do
        expect {
          described_class.new.perform(saved_hong_bao.id)
          saved_hong_bao.reload
        }.to change { saved_hong_bao.current_sats }.from(nil)
        expect(saved_hong_bao).to have_attributes(
          initial_sats: 41171,
          initial_spot: 0,
          current_sats: 41171,
          current_spot: 0.11429127e6,
          gifted_at: be_within(1.day).of(Time.utc(2025, 6, 23, 07)),
          last_fetched_at: be_present
        )
      end
    end

    it "does not sets initial valus if already set" do
      saved_hong_bao.update!(initial_sats: 1, initial_spot: 2)

      expect {
        expect {
          described_class.new.perform(saved_hong_bao.id)
          saved_hong_bao.reload
        }.not_to change { saved_hong_bao.initial_sats }.from(1)
      }.not_to change { saved_hong_bao.initial_spot }.from(2)
    end

    it "sets gifted_at from first transaction if not already set" do
      saved_hong_bao.update!(gifted_at: nil)

      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload

      expect(saved_hong_bao.gifted_at).not_to be_nil
    end

    it "updates current_spot with current market price" do
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload

      expect(saved_hong_bao.current_spot).to be > 0
    end

    it "updates last_fetched_at timestamp" do
      saved_hong_bao.update!(last_fetched_at: nil)
      time_before = Time.current

      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload

      expect(saved_hong_bao.last_fetched_at).to be_within(1.second).of(time_before)
    end

    it "raises error if saved hong bao not found" do
      expect {
        described_class.new.perform(999999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'fails gracefully if address has no transactions', vcr: { cassette_name: "refresh_saved_hong_bao_balance_job_no_transactions" } do
      saved_hong_bao.update!(address: "bc1q4mk80362m9typergc9rnueyf2u3ml4dn94ykhy", gifted_at: nil)

      expect {
        described_class.new.perform(saved_hong_bao.id)
      }.not_to raise_error
      expect(saved_hong_bao).to have_attributes(
        initial_sats: nil,
        initial_spot: 0,
        current_sats: nil,
        current_spot: 0,
        gifted_at: nil,
        status: { icon: "exclamation-triangle", text: "NO FUNDS", class: "text-error" },
        last_fetched_at: nil
      )
    end
  end
end
