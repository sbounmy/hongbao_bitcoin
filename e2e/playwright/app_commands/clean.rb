if defined?(DatabaseCleaner)
  # cleaning the database using database_cleaner
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean
else
  logger.warn "add database_cleaner or update cypress/app_commands/clean.rb"
  Post.delete_all if defined?(Post)
end

CypressOnRails::SmartFactoryWrapper.reload

if defined?(VCR)
  Rails.logger.info "VCR.eject_cassette"
  VCR.eject_cassette # make sure we no cassette inserted before the next test starts
  VCR.turn_off!
  WebMock.disable! if defined?(WebMock)
end

# Stub instagram to avoid polluting cassettes
InstagramService.class_eval do
  def fetch_media(*_args, **_kwargs, &_block)
    [] # Return an empty array as intended
  end
end


Rails.logger.info "APPCLEANED" # used by log_fail.rb
