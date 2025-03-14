require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out sensitive data
  config.filter_sensitive_data('<LEONARDO_API_KEY>') { Rails.application.credentials.dig(:leonardo, :api_key) }
end
