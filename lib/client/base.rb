require "net/http"
require "uri"
require "json"
require_relative "object"
require_relative "list_object"
require_relative "request"

module Client
  class Base
    attr_reader :api_key, :options

    CONTENT_TYPES = {
      JSON: "application/json",
      MULTIPART: "multipart/form-data"
    }.freeze

    def initialize(api_key: nil, **options)
      @api_key = api_key || default_api_key
      @options = options
    end

    class << self
      def get(path, as:, key: nil, content_type: Request::CONTENT_TYPES[:JSON])
        define_request_method(as, :get, path, key: key, content_type: content_type)
      end

      def post(path, as:, key: nil, content_type: Request::CONTENT_TYPES[:JSON])
        define_request_method(as, :post, path, key: key, content_type: content_type)
      end

      private

      def define_request_method(name, http_method, path, key: nil, content_type: nil)
        define_method(name) do |*args, **params|
          url = build_url(path, args, params)

          request = Request.new(
            http_method,
            url,
            content_type: content_type,
            **params
          )

          response = request.execute(api_key: api_key)
          handle_response(response, key)
        end
      end
    end

    private

    def build_url(path, args, params)
      final_path = path.dup
      path_params = path.scan(/:(\w+)/).flatten

      if path_params.any?
        param_values = args.first.is_a?(Hash) ? args.first : { path_params.first => args.first }

        path_params.each do |param|
          value = param_values[param.to_sym] || param_values[param]
          final_path.gsub!(":#{param}", value.to_s)
        end
      end

      "#{self.class::API_BASE_URL}#{final_path}"
    end

    def default_api_key
      Rails.application.credentials.dig(*api_key_credential_path)
    end

    def api_key_credential_path
      raise NotImplementedError, "Subclasses must define api_key_credential_path"
    end

    def handle_response(response, key)
      case response
      when Net::HTTPSuccess
        convert_to_client_object(parse_response(response.body), key)
      else
        handle_error_response(response)
      end
    end

    def parse_response(body)
      return {} if body.nil? || body.empty?

      begin
        JSON.parse(body)
      rescue JSON::ParserError
        body
      end
    end

    def handle_error_response(response)
      error_message = "#{response.code} #{response.message}"

      begin
        error_data = JSON.parse(response.body)
        error_message += ": #{error_data['error'] || error_data['message']}" if error_data["error"] || error_data["message"]
      rescue JSON::ParserError
        error_message += ": #{response.body}" unless response.body.nil? || response.body.empty?
      end

      raise "API Error: #{error_message}"
    end

    def convert_to_client_object(data, key)
      data_object = data.fetch(key, data)
      metadata = data.except(key)
      case data_object
      when Array
        ListObject.new("data" => data_object.map { |item| convert_to_client_object(item, nil) },
                       **metadata)
      when Hash
        Object.new(data_object)
      else
        data
      end
    end
  end
end
