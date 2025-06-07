module Client
  class Response
    attr_reader :raw, :key

    def initialize(raw, key: nil)
      @raw = raw
      @key = key
    end

    def handle
      Rails.logger.info("Response: #{raw.inspect}")
      case raw
      when Net::HTTPSuccess
        convert_to_client_object(parse, key)
      else
        handle_error
      end
    end

    private

    def parse
      return {} if raw.body.nil? || raw.body.empty?

      begin
        JSON.parse(raw.body)
      rescue JSON::ParserError
        raw.body
      end
    end

    def handle_error
      error_message = "#{raw.code} #{raw.message}"

      begin
        error_data = JSON.parse(raw.body)
        error_message += ": #{error_data['error'] || error_data['message']}" if error_data["error"] || error_data["message"]
      rescue JSON::ParserError
        error_message += ": #{raw.body}" unless raw.body.nil? || raw.body.empty?
      end

      raise "API Error: #{error_message}"
    end

    def convert_to_client_object(data, key)
      return data unless data.is_a?(Hash) || data.is_a?(Array)

      data_object = key ? data.fetch(key, data) : data
      metadata = data.is_a?(Hash) ? data.except(key) : {}

      case data_object
      when Array
        ListObject.new(
          "data" => data_object.map { |item| convert_to_client_object(item, nil) },
          **metadata
        )
      when Hash
        Object.new(data_object)
      else
        data_object
      end
    end
  end
end
