require 'rails_helper'

RSpec.describe BitcoinPortfolioService do
  describe '#call' do
    before do
      # Clean up existing spots and saved hong baos
      SavedHongBao.destroy_all
      Spot.destroy_all
    end

    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
    let!(:spot1) { Spot.create!(date: 27.days.ago.to_date, prices: { 'usd' => 30000 }) }
    let!(:spot2) { Spot.create!(date: 15.days.ago.to_date, prices: { 'usd' => 35000 }) }
    let!(:spot3) { Spot.create!(date: Date.today, prices: { 'usd' => 40000 }) }

    let!(:saved_hong_bao1) do
      SavedHongBao.create!(
        user: user,
        name: 'Hong Bao 1',
        address: 'bc1qyus6dre55lulasz5x5xtgsjtapjag54s5paulx',
        initial_sats: 100000,
        current_sats: 120000,
        gifted_at: 20.days.ago,
        spot_buy: spot1
      )
    end

    let!(:saved_hong_bao2) do
      SavedHongBao.create!(
        user: user,
        name: 'Hong Bao 2',
        address: 'bc1qtest2dre55lulasz5x5xtgsjtapjag54s5paul',
        initial_sats: 50000,
        current_sats: 50000,
        gifted_at: 10.days.ago,
        spot_buy: spot2
      )
    end

    let(:saved_hong_baos) { SavedHongBao.where(user: user) }
    let(:service) { described_class.new(saved_hong_baos) }

    describe 'returned data structure' do
      subject(:result) { service.call }

      it 'returns a hash with all required keys' do
        expect(result).to have_key(:btc_prices)
        expect(result).to have_key(:portfolio)
        expect(result).to have_key(:net_deposits)
        expect(result).to have_key(:hong_bao_markers)
      end

      it 'returns btc_prices as an array of timestamp-value pairs' do
        expect(result[:btc_prices]).to be_an(Array)
        expect(result[:btc_prices].first).to be_an(Array)
        expect(result[:btc_prices].first.size).to eq(2)
      end

      it 'returns portfolio values over time' do
        expect(result[:portfolio]).to be_an(Array)
        expect(result[:portfolio]).not_to be_empty
      end

      it 'returns cumulative net deposits' do
        expect(result[:net_deposits]).to be_an(Array)
        expect(result[:net_deposits]).not_to be_empty
      end

      it 'returns markers for each hong bao' do
        expect(result[:hong_bao_markers]).to be_an(Array)
        expect(result[:hong_bao_markers].size).to eq(2)

        marker = result[:hong_bao_markers].first
        expect(marker).to have_key(:x)
        expect(marker).to have_key(:y)
        expect(marker).to have_key(:name)
        expect(marker).to have_key(:address)
        expect(marker).to have_key(:initial_price)
        expect(marker).to have_key(:current_price)
        expect(marker).to have_key(:change_percent)
      end
    end

    describe 'date range calculation' do
      context 'when hong baos exist' do
        it 'returns btc prices for the correct date range' do
          result = service.call

          # Service should try to start 7 days before the earliest hong bao
          # which is 20 days ago, so 27 days ago
          # We have spot1 at 27 days ago to cover this

          btc_dates = result[:btc_prices].map { |point| Time.at(point[0] / 1000).to_date }

          expect(btc_dates).to include(spot1.date)
          expect(btc_dates).to include(spot2.date)
          expect(btc_dates).to include(spot3.date)
        end
      end

      context 'when no hong baos have gifted_at' do
        before do
          saved_hong_baos.update_all(gifted_at: nil)
        end

        it 'defaults to 30 days ago' do
          result = service.call
          first_date = Time.at(result[:btc_prices].first[0] / 1000).to_date
          expect(first_date).to be_within(1.day).of(30.days.ago.to_date)
        end
      end
    end

    describe 'currency support' do
      let!(:eur_spot) { Spot.create!(date: 5.days.ago.to_date, prices: { 'eur' => 36000 }) }
      let(:eur_service) { described_class.new(saved_hong_baos, currency: :eur) }

      it 'supports EUR currency' do
        result = eur_service.call
        expect(result[:btc_prices]).to include(
          [ eur_spot.date.to_time.to_i * 1000, 36000.0 ]
        )
      end
    end
  end
end
