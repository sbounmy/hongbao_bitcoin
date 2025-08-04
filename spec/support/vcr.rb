# frozen_string_literal: true

require 'vcr'

# Note: If you change this file, make sure you restart your playwright web server to see the changes
# This is also loaded in e2e/playwright/e2e_helper.rb
VCR.configure do |config|
  config.cassette_library_dir = ENV["CYPRESS"] ? 'e2e/playwright/fixtures/vcr_cassettes' : 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata! if ENV["CYPRESS"].nil?

  # Allow same request to be played back multiple times from 1 cassette
  config.default_cassette_options = { allow_playback_repeats: true }

  # Filter out sensitive data
  config.filter_sensitive_data('<LEONARDO_API_KEY>') { Rails.application.credentials.dig(:leonardo, :api_key) }
  config.filter_sensitive_data('<LEONARDO_WEBHOOK_TOKEN>') { Rails.application.credentials.dig(:leonardo, :webhook_token) }
  config.filter_sensitive_data('<INSTAGRAM_ACCESS_TOKEN>') { Rails.application.credentials.dig(:instagram, :token) }
  config.filter_sensitive_data('<FACE_SWAP_API_KEY>') { Rails.application.credentials.dig(:faceswap, :api_key) }
  config.filter_sensitive_data('<FACE_SWAP_WEBHOOK_TOKEN>') { Rails.application.credentials.dig(:faceswap, :webhook_token) }
  config.filter_sensitive_data('<STRIPE_SECRET_KEY>') { Rails.application.credentials.dig(:stripe, :secret_key) }
  config.filter_sensitive_data("<GOOGLE_CLIENT_ID>") { Rails.application.credentials.dig(:google, :client_id) }
  config.filter_sensitive_data("<GOOGLE_CLIENT_SECRET>") { Rails.application.credentials.dig(:google, :client_secret) }
  config.filter_sensitive_data("<OPENAI_API_KEY>") { Rails.application.credentials.dig(:openai, :api_key) }
  config.filter_sensitive_data("<BLOCKSTREAM_CLIENT_ID>") { Rails.application.credentials.dig(:blockstream, :client_id) }
  config.filter_sensitive_data("<BLOCKSTREAM_CLIENT_SECRET>") { Rails.application.credentials.dig(:blockstream, :client_secret) }
  config.filter_sensitive_data("<BTCPAY_API_KEY>") { Rails.application.credentials.dig(:btcpay, :api_key) }

  # Ignore Stripe checkout session requests as we need to checkout on Stripe's side
  config.ignore_request do |request|
    req = URI(request.uri)
    res = (req.path.match(%r{/v1/checkout/sessions}) && req.host == 'api.stripe.com')
    res ||= (req.path.match(%r{/v1/billing_portal/sessions}) && req.host == 'api.stripe.com')
    res ||= (req.path.match(%r{/api/v1/stores/.+/invoices}) && req.host == ENV["BTCPAY_HOST"])

    Rails.logger.info "[VCR] Ignoring request: #{req.host} #{req.path}" if res
    res
  end
end
