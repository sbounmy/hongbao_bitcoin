require "net/http"
require "uri"
require "json"
require_relative "object"
require_relative "list_object"

module Client
  class Base
    attr_reader :api_key, :options

    def initialize(api_key: nil, **options)
      @api_key = api_key || default_api_key
      @options = options
    end

    class << self
      def get(path, as:, key: nil, **options)
        define_request_method(as, :get, path, key: key, **options)
      end

      def post(path, as:, key: nil, **options)
        define_request_method(as, :post, path, key: key, **options)
      end

      private

      def define_request_method(name, http_method, path, key: nil, **options)
        define_method(name) do |*args, **params|
          # Extract path parameters from the path
          path_params = path.scan(/:(\w+)/).flatten

          # Build the final path by replacing parameters
          final_path = path.dup
          params_hash = {}

          if path_params.any?
            # If we have path params, first argument is treated as params object
            param_values = args.first.is_a?(Hash) ? args.first : { path_params.first => args.first }

            path_params.each do |param|
              value = param_values[param.to_sym] || param_values[param]
              final_path.gsub!(":#{param}", value.to_s)
            end
          end

          # Add any remaining params to query string
          params_hash = params if params.any?

          url = "#{self.class::API_BASE_URL}#{final_path}"
          response = request(http_method, url, params: params_hash)

          # If a specific key is provided, return just that part of the response
          handle_response(response, key)
        end
      end
    end

    private

    def default_api_key
      Rails.application.credentials.dig(*api_key_credential_path)
    end

    def api_key_credential_path
      raise NotImplementedError, "Subclasses must define api_key_credential_path"
    end

    def request(http_method, url, headers: {}, params: {}, form_data: nil)
      uri = URI(url)

      # Add query params for GET requests
      if http_method == :get && !params.empty?
        uri.query = URI.encode_www_form(params)
      end

      request = build_request(http_method, uri)

      # Add authorization header if api_key is present
      request["Authorization"] = "Bearer #{api_key}" if api_key

      # Add other headers
      headers.each { |key, value| request[key] = value }

      # Add form data for POST requests
      if form_data && [ :post, :put, :patch ].include?(http_method)
        if form_data.is_a?(Array) # multipart form data
          request.set_form(form_data, "multipart/form-data")
        else # regular form data
          request.set_form_data(form_data)
        end
      end

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    def build_request(http_method, uri)
      case http_method
      when :get
        Net::HTTP::Get.new(uri)
      when :post
        Net::HTTP::Post.new(uri)
      when :put
        Net::HTTP::Put.new(uri)
      when :patch
        Net::HTTP::Patch.new(uri)
      when :delete
        Net::HTTP::Delete.new(uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{http_method}"
      end
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
        Object.new(data)
      else
        data
      end
    end
  end
end
