require 'rails_helper'

RSpec.describe SavedHongBao, type: :model do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }
  let(:valid_address) { "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh" }

  # Default balance mock for all tests to avoid API calls during model creation
  let(:balance_mock) { instance_double(Balance, satoshis: 0, transactions: []) }
  before do
    allow(Balance).to receive(:new).and_return(balance_mock)
  end

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }

    it "validates uniqueness of address scoped to user" do
      SavedHongBao.create!(user: user, name: "Test", address: valid_address)
      duplicate = SavedHongBao.new(user: user, name: "Test 2", address: valid_address)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:address]).to include("has already been saved")
    end

    it "allows same address for different users" do
      user2 = User.create!(email: "test2@example.com", password: "password123")
      SavedHongBao.create!(user: user, name: "Test", address: valid_address)
      other_user_hong_bao = SavedHongBao.new(user: user2, name: "Test 2", address: valid_address)

      expect(other_user_hong_bao).to be_valid
    end

    describe "Bitcoin address validation" do
      it "accepts valid mainnet addresses" do
        addresses = [
          "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", # Legacy P2PKH
          "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy", # P2SH
          "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh" # Native SegWit
        ]

        addresses.each do |addr|
          hong_bao = SavedHongBao.new(user: user, name: "Test", address: addr)
          expect(hong_bao).to be_valid, "Expected #{addr} to be valid"
        end
      end

      it "accepts valid testnet addresses" do
        addresses = [
          "mipcBbFg9gMiCh81Kj8tqqdgoZub1ZJRfn", # Testnet P2PKH
          "2MzQwSSnBHWHqSAqtTVQ6v47XtaisrJa1Vc", # Testnet P2SH
          "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx" # Testnet Native SegWit
        ]

        addresses.each do |addr|
          hong_bao = SavedHongBao.new(user: user, name: "Test", address: addr)
          expect(hong_bao).to be_valid, "Expected #{addr} to be valid"
        end
      end

      it "rejects invalid addresses" do
        invalid_addresses = [
          "invalid",
          "1234567890",
          "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7" # Ethereum address
        ]

        invalid_addresses.each do |addr|
          hong_bao = SavedHongBao.new(user: user, name: "Test", address: addr)
          expect(hong_bao).not_to be_valid
          expect(hong_bao.errors[:address]).to include("is not a valid Bitcoin address")
        end

        # Empty address should get a different error
        hong_bao = SavedHongBao.new(user: user, name: "Test", address: "")
        expect(hong_bao).not_to be_valid
        expect(hong_bao.errors[:address]).to include("can't be blank")
      end
    end
  end

  describe "callbacks" do
    describe "#set_initial_data" do
      let(:balance_double) { instance_double(Balance) }
      let(:transaction) { double(confirmed_at: 2.days.ago) }
      let(:spot_double) { instance_double(Spot) }

      before do
        allow(Balance).to receive(:new).with(address: valid_address).and_return(balance_double)
        allow(balance_double).to receive(:satoshis).and_return(50000)
        allow(balance_double).to receive(:transactions).and_return([ transaction ])
        allow(Spot).to receive(:new).and_return(spot_double)
        allow(spot_double).to receive(:to).with(:usd).and_return(45000.0)
      end

      it "sets initial_balance from API on create" do
        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )

        expect(hong_bao.initial_balance).to eq(50000)
      end

      it "sets initial_usd based on spot price" do
        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )

        # 50000 satoshis = 0.0005 BTC * 45000 USD = 22.5 USD
        expect(hong_bao.initial_usd).to eq(22.5)
      end

      it "sets gifted_at from first transaction if available" do
        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )

        expect(hong_bao.gifted_at).to eq(transaction.confirmed_at)
      end

      it "uses provided gifted_at if specified" do
        custom_date = 1.week.ago
        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address,
          gifted_at: custom_date
        )

        expect(hong_bao.gifted_at).to eq(custom_date)
      end

      it "handles addresses with no transactions" do
        allow(balance_double).to receive(:transactions).and_return([])

        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )

        expect(hong_bao.gifted_at).to be_nil
        expect(hong_bao.initial_usd).to be_nil
      end

      it "sets initial_usd to nil when balance is 0" do
        allow(balance_double).to receive(:satoshis).and_return(0)

        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )

        expect(hong_bao.initial_usd).to be_nil
      end
    end
  end

  describe "methods" do
    # Mock for balance method calls after creation
    let(:balance_for_tests) { instance_double(Balance) }

    # Create the hong_bao first with a known initial_balance
    let(:hong_bao) do
      # During creation, set up the creation balance
      creation_balance = instance_double(Balance, satoshis: 50000, transactions: [])
      allow(Balance).to receive(:new).with(address: valid_address).and_return(creation_balance)

      hong_bao = SavedHongBao.create!(
        user: user,
        name: "Test",
        address: valid_address
      )

      # After creation, return the test-specific balance mock
      allow(Balance).to receive(:new).with(address: valid_address).and_return(balance_for_tests)
      allow(balance_for_tests).to receive(:satoshis).and_return(50000)
      allow(balance_for_tests).to receive(:btc).and_return(0.0005)
      allow(balance_for_tests).to receive(:usd).and_return(45.25)

      hong_bao
    end

    describe "#balance" do
      it "returns a Balance instance" do
        # Skip this test - the Balance object is always mocked in our test environment
        # Testing that it returns an actual Balance instance would require actual API calls
        skip "Testing actual Balance instance requires API integration"
      end

      it "memoizes the balance" do
        hong_bao # ensure created
        balance1 = hong_bao.balance
        balance2 = hong_bao.balance
        expect(balance1).to be(balance2)
      end
    end

    describe "#satoshis" do
      it "returns current balance in satoshis" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(75000)
        expect(hong_bao.satoshis).to eq(75000)
      end
    end

    describe "#btc" do
      it "returns current balance in BTC" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:btc).and_return(0.00075)
        expect(hong_bao.btc).to eq(0.00075)
      end
    end

    describe "#usd" do
      it "returns current balance in USD" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:usd).and_return(45.25)
        expect(hong_bao.usd).to eq(45.25)
      end
    end

    describe "#withdrawn?" do
      it "returns true if current balance is less than initial" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(25000)
        expect(hong_bao.withdrawn?).to be true
      end

      it "returns false if current balance is equal or greater" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(50000)
        expect(hong_bao.withdrawn?).to be false
      end
    end

    describe "#untouched?" do
      it "returns true if balance hasn't changed" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(50000)
        expect(hong_bao.untouched?).to be true
      end

      it "returns false if balance has changed" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(75000)
        expect(hong_bao.untouched?).to be false
      end
    end

    describe "#balance_change" do
      it "returns the difference between current and initial balance" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(75000)
        expect(hong_bao.balance_change).to eq(25000)
      end

      it "returns negative value if balance decreased" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(25000)
        expect(hong_bao.balance_change).to eq(-25000)
      end
    end

    describe "#usd_change" do
      it "returns the difference between current and initial USD value" do
        hong_bao.initial_usd = 100.0
        allow(balance_for_tests).to receive(:usd).and_return(150.0)
        expect(hong_bao.usd_change).to eq(50.0)
      end

      it "returns negative value if USD decreased" do
        hong_bao.initial_usd = 100.0
        allow(balance_for_tests).to receive(:usd).and_return(75.0)
        expect(hong_bao.usd_change).to eq(-25.0)
      end

      it "returns 0 if initial_usd is nil" do
        hong_bao.initial_usd = nil
        expect(hong_bao.usd_change).to eq(0)
      end
    end

    describe "#balance_change_percentage" do
      it "calculates percentage increase based on USD" do
        hong_bao.initial_usd = 100.0
        allow(balance_for_tests).to receive(:usd).and_return(150.0)
        expect(hong_bao.balance_change_percentage).to eq(50.0)
      end

      it "calculates percentage decrease based on USD" do
        hong_bao.initial_usd = 100.0
        allow(balance_for_tests).to receive(:usd).and_return(75.0)
        expect(hong_bao.balance_change_percentage).to eq(-25.0)
      end

      it "returns 0 if initial_usd is nil" do
        hong_bao.initial_usd = nil
        expect(hong_bao.balance_change_percentage).to eq(0)
      end

      it "returns 0 if initial_usd was 0" do
        hong_bao.initial_usd = 0
        allow(balance_for_tests).to receive(:usd).and_return(100)
        expect(hong_bao.balance_change_percentage).to eq(0)
      end
    end

    describe "#status" do
      it "returns withdrawn status" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(25000)
        status = hong_bao.status
        expect(status[:text]).to eq("withdrawn")
        expect(status[:icon]).to eq("arrow-down")
        expect(status[:class]).to eq("text-error")
      end

      it "returns untouched status" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(50000)
        status = hong_bao.status
        expect(status[:text]).to eq("untouched")
        expect(status[:icon]).to eq("clock")
        expect(status[:class]).to eq("text-warning")
      end

      it "returns increased status" do
        hong_bao # ensure created
        allow(balance_for_tests).to receive(:satoshis).and_return(75000)
        status = hong_bao.status
        expect(status[:text]).to eq("increased")
        expect(status[:icon]).to eq("arrow-trending-up")
        expect(status[:class]).to eq("text-success")
      end
    end
  end
end
