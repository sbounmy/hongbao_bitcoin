require 'rails_helper'

RSpec.describe RefreshSavedHongBaoBalanceJob, type: :job do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }
  let(:saved_hong_bao) do
    SavedHongBao.create!(
      user:,
      name: "Test Hong Bao",
      address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
    )
  end

  let(:balance_mock) { instance_double(Balance) }
  let(:transaction_mock) { double(satoshis: 100000, timestamp: 2.days.ago) }
  let(:spot_mock) { instance_double(Spot) }

  before do
    allow(Balance).to receive(:new).with(address: saved_hong_bao.address).and_return(balance_mock)
    allow(balance_mock).to receive(:transactions).and_return([transaction_mock])
    allow(balance_mock).to receive(:satoshis).and_return(150000)
    
    allow(Spot).to receive(:new).and_return(spot_mock)
    allow(spot_mock).to receive(:to).with(:usd).and_return(45000.0)
    allow(Spot).to receive(:current).with(:usd).and_return(50000.0)
  end

  describe "#perform" do
    it "updates the saved hong bao with current balance information" do
      expect {
        described_class.new.perform(saved_hong_bao.id)
        saved_hong_bao.reload
      }.to change { saved_hong_bao.current_sats }.from(nil).to(150000)
    end

    it "sets initial_sats if not already set" do
      saved_hong_bao.update!(initial_sats: nil)
      
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      expect(saved_hong_bao.initial_sats).to eq(100000)
    end

    it "does not override initial_sats if already set" do
      saved_hong_bao.update!(initial_sats: 50000)
      
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      expect(saved_hong_bao.initial_sats).to eq(50000)
    end

    it "sets initial_spot if not already set" do
      saved_hong_bao.update!(initial_spot: nil)
      
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      expect(saved_hong_bao.initial_spot).to eq(45000.0)
    end

    it "sets gifted_at from first transaction if not already set" do
      saved_hong_bao.update!(gifted_at: nil)
      
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      expect(saved_hong_bao.gifted_at).to eq(transaction_mock.timestamp)
    end

    it "updates current_spot with current market price" do
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      expect(saved_hong_bao.current_spot).to eq(50000.0)
    end

    it "updates last_fetched_at timestamp" do
      time_before = Time.current
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      expect(saved_hong_bao.last_fetched_at).to be_within(1.second).of(time_before)
    end

    it "handles addresses with no transactions" do
      allow(balance_mock).to receive(:transactions).and_return([])
      allow(balance_mock).to receive(:satoshis).and_return(0)
      
      described_class.new.perform(saved_hong_bao.id)
      saved_hong_bao.reload
      
      # When there are no transactions, initial_sats gets set to 0 from balance.satoshis
      expect(saved_hong_bao.initial_sats).to eq(0)
      expect(saved_hong_bao.initial_spot).to eq(45000.0)  # Still gets set from Spot.new
      expect(saved_hong_bao.gifted_at).to be_nil
      expect(saved_hong_bao.current_sats).to eq(0)
    end

    it "raises error if saved hong bao not found" do
      expect {
        described_class.new.perform(999999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end