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
      attr_reader :base_url

      def url(value)
        @base_url = value.freeze
      end

      def url_for(path)
        "#{base_url}#{path}"
      end

      def get(path, as:, key: nil, content_type: nil)
        define_request_method(as, :get, path, key: key, content_type:)
      end

      def post(path, as:, key: nil, content_type: nil)
        define_request_method(as, :post, path, key: key, content_type:)
      end

      private

      def define_request_method(name, http_method, path, key: nil, content_type: Request::CONTENT_TYPES[:JSON])
        define_method(name) do |*args, **params|
          url = build_url(path, args, params)

          request = Request.new(
            http_method,
            url,
            content_type: content_type,
            **params
          )

          response = request.execute(api_key: api_key)
          Response.new(response, key: key).handle
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

      "#{self.class.base_url}#{final_path}"
    end

    def default_api_key
      Rails.application.credentials.dig(*api_key_credential_path)
    end

    def api_key_credential_path
      raise NotImplementedError, "Subclasses must define api_key_credential_path"
    end
  end
end
