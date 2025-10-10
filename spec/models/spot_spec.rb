require 'rails_helper'

RSpec.describe Spot, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:date) }
    it { should validate_uniqueness_of(:date) }
  end

  describe 'scopes' do
    before do
      # Clean up any existing spots first
      SavedHongBao.destroy_all
      Spot.destroy_all

      # Create test spots with different currency prices
      Spot.create!(date: 2.days.ago, prices: { 'usd' => 50000, 'eur' => 45000 })
      Spot.create!(date: 1.day.ago, prices: { 'usd' => 51000 })
      Spot.create!(date: Date.today, prices: { 'usd' => 52000, 'eur' => 47000 })
    end

    describe '.currency_exists' do
      it 'returns spots with the specified currency' do
        expect(Spot.currency_exists(:usd).count).to eq(3)
        expect(Spot.currency_exists(:eur).count).to eq(2)
      end

      it 'raises an error for unsupported currency' do
        expect { Spot.currency_exists(:gbp) }.to raise_error(ArgumentError, /Unsupported currency: gbp/)
      end

      it 'protects against SQL injection attempts' do
        # Attempt SQL injection with malicious input
        malicious_input = "usd') OR 1=1 --"
        expect { Spot.currency_exists(malicious_input) }.to raise_error(ArgumentError, /Unsupported currency/)
      end

      it 'handles string and symbol input' do
        expect(Spot.currency_exists('usd').count).to eq(3)
        expect(Spot.currency_exists(:usd).count).to eq(3)
      end
    end

    describe '.current' do
      it 'returns the most recent spot with the specified currency' do
        current_usd = Spot.current(:usd)
        expect(current_usd.date).to eq(Date.today)
        expect(current_usd.prices['usd']).to eq(52000)
      end

      it 'returns the most recent spot with EUR even if today has no EUR' do
        # Remove EUR from today's spot
        today_spot = Spot.find_by(date: Date.today)
        today_spot.update!(prices: { 'usd' => 52000 })

        current_eur = Spot.current(:eur)
        expect(current_eur.date).to eq(2.days.ago.to_date)
        expect(current_eur.prices['eur']).to eq(45000)
      end

      it 'raises an error for unsupported currency' do
        expect { Spot.current(:jpy) }.to raise_error(ArgumentError, /Unsupported currency: jpy/)
      end

      it 'protects against SQL injection attempts' do
        malicious_input = "usd') OR 1=1; DROP TABLE spots; --"
        expect { Spot.current(malicious_input) }.to raise_error(ArgumentError, /Unsupported currency/)
      end
    end
  end


  describe 'CURRENCIES constant' do
    it 'contains expected currencies' do
      expect(Spot::CURRENCIES).to eq([ :usd, :eur ])
    end

    it 'is frozen to prevent modification' do
      expect(Spot::CURRENCIES).to be_frozen
    end
  end
end
