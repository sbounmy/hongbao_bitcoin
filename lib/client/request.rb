module Client
  class Request
    attr_reader :http_method, :url, :params, :headers, :files

    CONTENT_TYPES = {
      JSON: "application/json",
      MULTIPART: "multipart/form-data",
      FORM: "application/x-www-form-urlencoded"
    }.freeze

    VALID_HTTP_METHODS = [ :get, :post, :put, :patch, :delete ].freeze

    def initialize(http_method, url, content_type: CONTENT_TYPES[:JSON], **options)
      raise ArgumentError, "Unsupported HTTP method: #{http_method}" unless VALID_HTTP_METHODS.include?(http_method)

      @http_method = http_method
      @url = url
      @params = options.except(:headers, :files)
      @headers = options[:headers] || {}
      @files = options[:files]
      @headers["Content-Type"] ||= content_type
    end

    def execute(api_key: nil)
      uri = build_uri
      request = build_http_request
      add_authorization(request, api_key)
      add_headers(request)
      add_body(request)

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    private

    def build_uri
      uri = URI(url)
      if http_method == :get && params.any?
        uri.query = URI.encode_www_form(params)
      end
      uri
    end

    def build_http_request
      klass = case http_method
      when :get    then Net::HTTP::Get
      when :post   then Net::HTTP::Post
      when :put    then Net::HTTP::Put
      when :patch  then Net::HTTP::Patch
      when :delete then Net::HTTP::Delete
      end
      klass.new(build_uri)
    end

    def add_authorization(request, api_key)
      request["Authorization"] = "Bearer #{api_key}" if api_key
    end

    def add_headers(request)
      headers.each { |key, value| request[key] = value }
    end

    def add_body(request)
      return if http_method == :get || params.empty?

      case headers["Content-Type"]
      when CONTENT_TYPES[:JSON]
        request.body = params.to_json
      when CONTENT_TYPES[:MULTIPART]
        if files
          form_data = build_multipart_form_data
          request.set_form(form_data, "multipart/form-data")
        end
      else
        request.set_form_data(params)
      end
    end

    def build_multipart_form_data
      form_data = []

      # Add files first
      files.each do |key, file|
        form_data << [
          key.to_s,
          file.download,
          { filename: "#{key}.jpg" }
        ]
      end

      # Add remaining params
      params.each do |key, value|
        form_data << [ key.to_s, value.to_s ]
      end

      form_data
    end
  end
end
