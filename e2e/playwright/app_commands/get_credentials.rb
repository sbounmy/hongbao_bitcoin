key = command_options.to_sym
credentials = Rails.application.credentials[key]
if credentials
  credentials
else
  raise "Credentials for '#{key}' not found in Rails credentials for the test environment."
end
