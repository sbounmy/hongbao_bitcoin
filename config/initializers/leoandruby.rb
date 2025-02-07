# config/initializers/leoandruby.rb

# Configure the API token for verifying Leonardo.ai webhook requests
LeoAndRuby.config = {
  webhook_token: ENV.fetch("LEONARDO_WEBHOOK_TOKEN", "e2ce1665-0274-4c6c-af9e-9945e635a8d0")
}
