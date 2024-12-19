class BitcoinPriceFetcher
  BASE_URL = "https://api.coinbase.com/v2/prices/BTC-%s/spot"

  def self.fetch_historical_prices
    start_date = if BitcoinPrice.exists?
                   BitcoinPrice.order(date: :desc).first.date + 1.day
    else
                   Date.new(2013, 9, 1)
    end
    end_date = Date.current

    return if start_date > end_date

    (start_date..end_date).each do |date|
      [ "USD" ].each do |currency|
        formatted_date = date.strftime("%Y-%m-%d")
        uri = URI("#{BASE_URL % currency}?date=#{formatted_date}")

        begin
          response = Net::HTTP.get(uri)
          data = JSON.parse(response)
          price = data.dig("data", "amount")&.to_f

          if price && price > 0
            BitcoinPrice.create!(
              date: date,
              price: price,
              currency: currency
            )
            puts "Stored #{currency} price for #{formatted_date}: #{price}"
          end

          # Sleep to respect rate limits
          sleep 0.5

        rescue StandardError => e
          puts "Error fetching #{currency} price for #{formatted_date}: #{e.message}"
        end
      end
    end
  end
end
