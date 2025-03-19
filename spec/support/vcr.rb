require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out sensitive data
  config.filter_sensitive_data('<LEONARDO_API_KEY>') { Rails.application.credentials.dig(:leonardo, :api_key) }
  config.filter_sensitive_data('<LEONARDO_WEBHOOK_TOKEN>') { Rails.application.credentials.dig(:leonardo, :webhook_token) }
  config.filter_sensitive_data('<INSTAGRAM_ACCESS_TOKEN>') { Rails.application.credentials.dig(:instagram, :token) }
  config.filter_sensitive_data('<FACE_SWAP_API_KEY>') { Rails.application.credentials.dig(:faceswap, :api_key) }
  config.filter_sensitive_data('<FACE_SWAP_WEBHOOK_TOKEN>') { Rails.application.credentials.dig(:faceswap, :webhook_token) }
end
