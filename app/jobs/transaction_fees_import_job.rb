require "net/http"
require "json"

class TransactionFeesImportJob < ApplicationJob
  queue_as :default

  # Add recurring schedule - will run every hour
  include SolidQueue::Recurring
  recurring every: 1.day

  MEMPOOL_API = "https://mempool.space/api/v1/fees/recommended"

  def perform
    return if TransactionFee.exists?(date: Date.current)

    priorities = fetch_current_fees
    TransactionFee.create!(
      date: Date.current,
      priorities: priorities
    )
  end

  private

  def fetch_current_fees
    uri = URI(MEMPOOL_API)
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)

    {
      "fast" => data["fastestFee"],      # sat/vB for next block
      "half_hour" => data["halfHourFee"], # sat/vB for ~30 min
      "hour" => data["hourFee"],         # sat/vB for ~1 hour
      "eco" => data["economyFee"],      # sat/vB for economic fee
      "minimum" => data["minimumFee"]   # sat/vB for minimum fee
    }
  end
end
