module Client
  class Request
    attr_reader :http_method, :url, :params, :headers

    CONTENT_TYPES = {
      JSON: "application/json",
      MULTIPART: "multipart/form-data",
      FORM: "application/x-www-form-urlencoded"
    }.freeze

    VALID_HTTP_METHODS = [ :get, :post, :put, :patch, :delete ].freeze

    def initialize(http_method, url, **options)
      raise ArgumentError, "Unsupported HTTP method: #{http_method}" unless VALID_HTTP_METHODS.include?(http_method)

      @http_method = http_method
      @url = url
      @headers = options.delete(:headers) || {}

      # Automatically detect if we have file uploads
      @files, @params = extract_files_and_params(options)

      # Set content type based on params
      @headers["Content-Type"] ||= determine_content_type
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

    def extract_files_and_params(options)
      files = {}
      params = {}

      options.each do |key, value|
        if file_like?(value)
          files[key] = value
        else
          params[key] = value
        end
      end

      [ files, params ]
    end

    def file_like?(value)
      # Check for common file-like objects
      # ActiveStorage::Blob, File, Tempfile, StringIO, etc.
      value.respond_to?(:read) ||
        value.respond_to?(:download) ||
        value.is_a?(File) ||
        value.is_a?(Tempfile) ||
        value.is_a?(StringIO)
    end

    def determine_content_type
      return @headers["Content-Type"] if @headers["Content-Type"]
      return CONTENT_TYPES[:MULTIPART] if @files.any?
      # Always default to JSON unless explicitly set otherwise
      CONTENT_TYPES[:JSON]
    end

    def add_body(request)
      return if http_method == :get

      if @files.any?
        form_data = build_multipart_form_data
        request.set_form(form_data, "multipart/form-data")
      elsif @params.any?
        if headers["Content-Type"] == CONTENT_TYPES[:JSON]
          request.body = @params.to_json
        else
          request.set_form_data(@params)
        end
      end
    end

    def build_multipart_form_data
      form_data = []

      # Add files
      @files.each do |key, file|
        file_data = file.respond_to?(:download) ? file.download : file.read
        form_data << [
          key.to_s,
          file_data,
          { filename: "#{key}.jpg" } # You might want to detect actual file extension
        ]
      end

      # Add regular params
      @params.each do |key, value|
        form_data << [ key.to_s, value.to_s ]
      end

      form_data
    end
  end
end
