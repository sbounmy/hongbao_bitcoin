require 'rails_helper'

RSpec.describe Input::Event, type: :model do
  fixtures :inputs

  describe '.order_by_upcoming_anniversary' do
    context 'with the current date being March 3rd' do
      before do
        Timecop.freeze(Date.new(2025, 03, 03))
      end

      after do
        Timecop.return
      end

      it 'orders events by their upcoming anniversary' do
        ordered_events = described_class.find_by_anniversary

        expected_order = [
          inputs(:satoshi_sayonara), # April 23
          inputs(:pizza_day),       # May 22
          inputs(:whitepaper),      # October 31
          inputs(:first_halving),   # November 28
          inputs(:genesis),         # January 03
          inputs(:first_transaction) # January 12
        ]

        # We must filter only for events, since inputs.yml contains other types
        expect(ordered_events.to_a).to eq(expected_order.select { |i| i.is_a?(Input::Event) })
        expect(ordered_events.map(&:anniversary)).to eq([
          Date.new(2025, 04, 23),
          Date.new(2025, 05, 22),
          Date.new(2025, 10, 31),
          Date.new(2025, 11, 28),
          Date.new(2026, 01, 03),
          Date.new(2026, 01, 12)
        ])
      end
    end
  end
end
