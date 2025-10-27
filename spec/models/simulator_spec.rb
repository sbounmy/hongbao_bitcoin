# frozen_string_literal: true

require "rails_helper"

RSpec.describe Simulator, type: :model do
  describe "#initialize" do
    it "sets default years" do
      simulator = described_class.new
      expect(simulator.years).to eq(5)
    end

    it "initializes with default events attributes" do
      simulator = described_class.new
      expect(simulator.events_attributes).to be_present
      expect(simulator.events_attributes["christmas"][:amount]).to eq(50)
      expect(simulator.events_attributes["new_year"][:amount]).to eq(50)
      expect(simulator.events_attributes["birthday"][:amount]).to eq(100)
      expect(simulator.events_attributes["chinese_new_year"][:amount]).to eq(0)
    end

    it "accepts custom years" do
      simulator = described_class.new(years: 10)
      expect(simulator.years).to eq(10)
    end
  end

  describe "#to_service_params" do
    let(:simulator) { described_class.new }

    context "with valid events" do
      before do
        simulator.events_attributes = {
          "christmas" => { amount: 100 },
          "birthday" => { amount: 50, month: 6, day: 15 },
          "new_year" => { amount: 75 },
          "chinese_new_year" => { amount: 0 }
        }
      end

      it "includes events with amounts > 0" do
        params = simulator.to_service_params
        expect(params[:events]).to contain_exactly(:christmas, :birthday, :new_year)
        expect(params[:event_amounts]).to eq({
          christmas: 100.0,
          birthday: 50.0,
          new_year: 75.0
        })
      end

      it "includes custom birthday date" do
        params = simulator.to_service_params
        expect(params[:birthday_month]).to eq(6)
        expect(params[:birthday_day]).to eq(15)
      end

      it "excludes events with zero amount" do
        params = simulator.to_service_params
        expect(params[:events]).not_to include(:chinese_new_year)
      end
    end

    context "with default values" do
      it "returns empty events when all amounts are zero or negative" do
        simulator.events_attributes = {
          "christmas" => { amount: 0 },
          "birthday" => { amount: -10 }
        }
        params = simulator.to_service_params
        expect(params[:events]).to be_empty
        expect(params[:event_amounts]).to be_empty
      end
    end
  end

  describe ".calculate_event_date" do
    context "birthday event" do
      let(:year) { 2024 }

      it "calculates valid birthday date" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_month: 4, birthday_day: 5)
        expect(date).to eq(Date.new(2024, 4, 5))
      end

      it "handles February 29th on non-leap years" do
        date = described_class.calculate_event_date(:birthday, 2023,
          birthday_month: 2, birthday_day: 29)
        expect(date).to eq(Date.new(2023, 2, 28))
      end

      it "handles February 29th on leap years" do
        date = described_class.calculate_event_date(:birthday, 2024,
          birthday_month: 2, birthday_day: 29)
        expect(date).to eq(Date.new(2024, 2, 29))
      end

      it "handles April 31st (invalid date) by using April 30th" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_month: 4, birthday_day: 31)
        expect(date).to eq(Date.new(2024, 4, 30))
      end

      it "handles June 31st (invalid date) by using June 30th" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_month: 6, birthday_day: 31)
        expect(date).to eq(Date.new(2024, 6, 30))
      end

      it "handles September 31st (invalid date) by using September 30th" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_month: 9, birthday_day: 31)
        expect(date).to eq(Date.new(2024, 9, 30))
      end

      it "handles November 31st (invalid date) by using November 30th" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_month: 11, birthday_day: 31)
        expect(date).to eq(Date.new(2024, 11, 30))
      end

      it "handles February 30th/31st by using last day of February" do
        # Non-leap year
        date = described_class.calculate_event_date(:birthday, 2023,
          birthday_month: 2, birthday_day: 31)
        expect(date).to eq(Date.new(2023, 2, 28))

        date = described_class.calculate_event_date(:birthday, 2023,
          birthday_month: 2, birthday_day: 30)
        expect(date).to eq(Date.new(2023, 2, 28))

        # Leap year
        date = described_class.calculate_event_date(:birthday, 2024,
          birthday_month: 2, birthday_day: 31)
        expect(date).to eq(Date.new(2024, 2, 29))

        date = described_class.calculate_event_date(:birthday, 2024,
          birthday_month: 2, birthday_day: 30)
        expect(date).to eq(Date.new(2024, 2, 29))
      end

      it "returns nil when birthday month is missing" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_day: 5)
        expect(date).to be_nil
      end

      it "returns nil when birthday day is missing" do
        date = described_class.calculate_event_date(:birthday, year,
          birthday_month: 4)
        expect(date).to be_nil
      end
    end

    context "fixed date events" do
      it "calculates Christmas date" do
        date = described_class.calculate_event_date(:christmas, 2024)
        expect(date).to eq(Date.new(2024, 12, 25))
      end

      it "calculates New Year date" do
        date = described_class.calculate_event_date(:new_year, 2024)
        expect(date).to eq(Date.new(2024, 1, 1))
      end
    end
  end

  describe ".event_config" do
    it "returns event configuration for valid event" do
      config = described_class.event_config(:christmas)
      expect(config[:label]).to eq("Christmas")
      expect(config[:emoji]).to eq("🎄")
      expect(config[:default_amount]).to eq(50)
    end

    it "returns nil for invalid event" do
      config = described_class.event_config(:invalid_event)
      expect(config).to be_nil
    end
  end

  describe ".event_color" do
    it "returns color for valid event" do
      expect(described_class.event_color(:christmas)).to eq("#dc2626")
      expect(described_class.event_color(:birthday)).to eq("#ec4899")
    end

    it "returns default color for invalid event" do
      expect(described_class.event_color(:invalid_event)).to eq("#6b7280")
    end
  end

  describe ".default_params" do
    it "returns default service parameters" do
      params = described_class.default_params
      expect(params[:years]).to eq(5)
      expect(params[:currency]).to eq(:usd)
      expect(params[:birthday_month]).to eq(4)
      expect(params[:birthday_day]).to eq(5)
    end
  end

  describe "EventHongBao" do
    let(:event_hong_bao) do
      Simulator::EventHongBao.new(
        gifted_at: Date.new(2024, 1, 1),
        initial_sats: 100_000,
        current_sats: 150_000,
        initial_usd: 50,
        name: "New Year Gift",
        event_type: :new_year,
        event_emoji: "🎊",
        event_color: "#f59e0b"
      )
    end

    it "calculates btc from sats" do
      expect(event_hong_bao.btc).to eq(0.0015)
    end

    it "calculates initial_btc from initial_sats" do
      expect(event_hong_bao.initial_btc).to eq(0.001)
    end

    it "provides compatibility methods" do
      expect(event_hong_bao.id).to be_nil
      expect(event_hong_bao.address).to be_nil
      expect(event_hong_bao.avatar_url).to be_nil
      expect(event_hong_bao.status).to eq({ text: "simulated" })
    end

    it "provides a simulated user" do
      user = event_hong_bao.user
      expect(user.id).to eq(0)
      expect(user.email).to eq("simulator@hongbao.tc")
    end
  end
end
