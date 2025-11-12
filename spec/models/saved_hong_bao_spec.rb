require 'rails_helper'

RSpec.describe SavedHongBao, type: :model do
  let(:user) { users(:satoshi) }
  let(:valid_address) { "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh" }

  # Mock the background job that fetches balance data
  before do
    allow(RefreshSavedHongBaoBalanceJob).to receive(:perform_later)
  end

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }

    it "validates uniqueness of address scoped to user" do
      duplicate = SavedHongBao.new(user: user, name: "Test 2", address: saved_hong_baos(:hodl).address)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:address]).to include("has already been saved")
    end

    it "allows same address for different users" do
      other_user_hong_bao = SavedHongBao.new(user: users(:two), name: "Test", address: saved_hong_baos(:withdraw).address)
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

    describe "file attachment" do
      let(:hong_bao) { SavedHongBao.new(user: user, name: "Test", address: valid_address) }

      it "accepts file attachments" do
        file = fixture_file_upload('spec/fixtures/files/test.pdf', 'application/pdf')
        hong_bao.file.attach(file)
        expect(hong_bao).to be_valid
      end

      it "validates file size" do
        # Create a large file mock
        large_file = double('file')
        allow(large_file).to receive(:blob).and_return(double('blob', byte_size: 11.megabytes))
        allow(hong_bao).to receive(:file).and_return(double('attachment', attached?: true, blob: double('blob', byte_size: 11.megabytes)))

        expect(hong_bao).not_to be_valid
        expect(hong_bao.errors[:file]).to include("size should be less than 10MB")
      end

      it "is valid without a file attachment" do
        expect(hong_bao).to be_valid
      end
    end
  end

  describe "callbacks" do
    describe "#schedule_balance_refresh" do
      it "schedules a background job on create" do
        expect(RefreshSavedHongBaoBalanceJob).to receive(:perform_later)

        SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )
      end
    end

    describe "broadcasting" do
      it "broadcasts prepend on create" do
        hong_bao = SavedHongBao.new(
          user: user,
          name: "Test",
          address: valid_address
        )

        expect(hong_bao).to receive(:broadcast_prepend_to_user)
        hong_bao.save!
      end

      it "broadcasts replace on update" do
        hong_bao = SavedHongBao.create!(
          user: user,
          name: "Test",
          address: valid_address
        )

        expect(hong_bao).to receive(:broadcast_replace_to_user)
        hong_bao.update!(name: "Updated")
      end
    end
  end

  describe "methods" do
    let(:hong_bao) { saved_hong_baos(:hodl) }

    describe "#btc" do
      it "returns current balance in BTC from cached sats" do
        hong_bao.update!(current_sats: 75000)
        expect(hong_bao.btc).to eq(0.00075)
      end

      it "returns 0 when current_sats is nil" do
        hong_bao.update!(current_sats: nil)
        expect(hong_bao.btc).to eq(0)
      end
    end

    describe "#usd" do
      it "returns current balance in USD from cached values" do
        spots(:today).update prices: { usd: 45000 }
        hong_bao.update!(current_sats: 100000)
        # 100000 sats = 0.001 BTC * 45000 = 45.0 USD
        expect(hong_bao.usd).to eq(45.0)
      end

      it "returns 0 when current_sats is nil" do
        hong_bao.update!(current_sats: nil)
        expect(hong_bao.usd).to eq(0)
      end
    end

    describe "#initial_btc" do
      it "returns initial balance in BTC" do
        hong_bao.update!(initial_sats: 75000)
        expect(hong_bao.initial_btc).to eq(0.00075)
      end
    end

    describe "#initial_usd" do
      it "returns initial value in USD" do
        spots(:past).update prices: { usd: 45000 }
        hong_bao.update!(initial_sats: 100000)
        expect(hong_bao.initial_usd).to eq(45.0)
      end
    end

    describe "#withdrawn?" do
      it "returns true if current balance is zero" do
        hong_bao.update!(current_sats: 0)
        expect(hong_bao.withdrawn?).to be true
      end

      it "returns false if current balance is not zero" do
        hong_bao.update!(current_sats: 50000)
        expect(hong_bao.withdrawn?).to be false
      end
    end

    describe "#untouched?" do
      it "returns true if balance hasn't changed" do
        hong_bao.update!(initial_sats: 50000, current_sats: 50000)
        expect(hong_bao.untouched?).to be true
      end

      it "returns false if balance has changed" do
        hong_bao.update!(initial_sats: 50000, current_sats: 75000)
        expect(hong_bao.untouched?).to be false
      end
    end

    describe "#balance_change" do
      it "returns the difference between current and initial balance" do
        hong_bao.update!(initial_sats: 50000, current_sats: 75000)
        expect(hong_bao.balance_change).to eq(25000)
      end

      it "returns negative value if balance decreased" do
        hong_bao.update!(initial_sats: 50000, current_sats: 25000)
        expect(hong_bao.balance_change).to eq(-25000)
      end

      it "handles nil values" do
        hong_bao.update!(initial_sats: nil, current_sats: nil)
        expect(hong_bao.balance_change).to eq(0)
      end
    end

    describe "#usd_change" do
      it "returns the difference between current and initial USD value" do
        spots(:past).update prices: { usd: 40000 }
        spots(:today).update prices: { usd: 50000 }
        hong_bao.update!(
          initial_sats: 100000,
          current_sats: 100000,
        )
        # Same sats but higher price: 0.001 BTC * (50000 - 40000) = 10.0 USD gain
        expect(hong_bao.usd_change).to eq(10.0)
      end

      it "returns negative value if USD decreased" do
        spots(:past).update prices: { usd: 50000 }
        spots(:today).update prices: { usd: 40000 }
        hong_bao.update!(
          initial_sats: 100000,
          current_sats: 100000,
        )
        expect(hong_bao.usd_change).to eq(-10)
      end
    end

    describe "#balance_change_percentage" do
      it "calculates percentage increase based on USD" do
        hong_bao.update!(
          initial_sats: 100000,
          current_sats: 100000,
        )
        # 40 USD to 60 USD = 50% increase
        expect(hong_bao.balance_change_percentage).to eq(9900)
      end

      it "calculates percentage decrease based on USD" do
        spots(:today).update prices: { usd: 5 }
        hong_bao.update!(
          initial_sats: 100000,
          current_sats: 100000,
        )
        # 100 USD to 10 000 USD = increase of 9900%
        expect(hong_bao.balance_change_percentage).to eq(-95)
      end

      it "returns 0 if initial_usd was 0" do
        hong_bao.update!(initial_sats: 0, initial_spot: 40000.0)
        expect(hong_bao.balance_change_percentage).to eq(0)
      end
    end

    describe "#status_display" do
      it "returns withdrawn status display when status is withdrawn" do
        hong_bao.update!(status: "withdrawn")
        status = hong_bao.status_display
        expect(status[:text]).to eq("WITHDRAWN")
        expect(status[:icon]).to eq("check-circle")
        expect(status[:class]).to eq("text-success")
      end

      it "returns hodl status display when status is hodl" do
        hong_bao.update!(status: "hodl")
        status = hong_bao.status_display
        expect(status[:text]).to eq("HODL")
        expect(status[:icon]).to eq("hand-thumb-up")
        expect(status[:class]).to eq("text-warning")
      end

      it "returns lost status display when status is lost" do
        hong_bao.update!(status: "lost")
        status = hong_bao.status_display
        expect(status[:text]).to eq("LOST")
        expect(status[:icon]).to eq("exclamation-circle")
        expect(status[:class]).to eq("text-error")
      end
    end

    describe "#needs_refresh?" do
      it "returns true if last_fetched_at is nil" do
        hong_bao.update!(last_fetched_at: nil)
        expect(hong_bao.needs_refresh?).to be true
      end

      it "returns true if last_fetched_at is more than 1 hour ago" do
        hong_bao.update!(last_fetched_at: 2.hours.ago)
        expect(hong_bao.needs_refresh?).to be true
      end

      it "returns false if last_fetched_at is recent" do
        hong_bao.update!(last_fetched_at: 30.minutes.ago)
        expect(hong_bao.needs_refresh?).to be false
      end
    end
  end
end
