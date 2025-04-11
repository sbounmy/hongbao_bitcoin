require 'vcr'

# This is also loaded in e2e/playwright/e2e_helper.rb
VCR.configure do |config|
  config.cassette_library_dir = ENV["CYPRESS"] ? 'e2e/playwright/e2e/fixtures/vcr_cassettes' : 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata! if ENV["CYPRESS"].nil?

  # Filter out sensitive data
  config.filter_sensitive_data('<LEONARDO_API_KEY>') { Rails.application.credentials.dig(:leonardo, :api_key) }
  config.filter_sensitive_data('<LEONARDO_WEBHOOK_TOKEN>') { Rails.application.credentials.dig(:leonardo, :webhook_token) }
  config.filter_sensitive_data('<INSTAGRAM_ACCESS_TOKEN>') { Rails.application.credentials.dig(:instagram, :token) }
  config.filter_sensitive_data('<FACE_SWAP_API_KEY>') { Rails.application.credentials.dig(:faceswap, :api_key) }
  config.filter_sensitive_data('<FACE_SWAP_WEBHOOK_TOKEN>') { Rails.application.credentials.dig(:faceswap, :webhook_token) }
  config.filter_sensitive_data('<STRIPE_SECRET_KEY>') { Rails.application.credentials.dig(:stripe, :secret_key) }

  # Ignore Stripe checkout session requests as we need to checkout on Stripe's side
  config.ignore_request do |request|
    req = URI(request.uri)
    res = (req.path == '/v1/checkout/sessions' && req.host == 'api.stripe.com')
    Rails.logger.info "[VCR] Ignoring request: #{req.host} #{req.path}" if res
    res
  end
end
