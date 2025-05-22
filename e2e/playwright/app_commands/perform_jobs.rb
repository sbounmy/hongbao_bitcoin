# Load Rails environment if not already loaded
require_relative '../../config/environment' unless defined?(Rails)

class JobRunner
  # Include ActiveJob TestHelper to get perform_enqueued_jobs
  # This ensures the methods are available on instances of JobRunner
  include ActiveJob::TestHelper

  def perform_jobs
    puts "Performing jobs (inside JobRunner)..."
    Rails.logger.info "[JobRunner] Attempting perform_enqueued_jobs (using ActiveJob::TestHelper)..."

    # Perform jobs enqueued via the :test adapter
    # Now called on `self`, which includes the TestHelper module
    perform_enqueued_jobs

    Rails.logger.info "[JobRunner] ActiveJob::TestHelper.perform_enqueued_jobs finished."
    puts "[JobRunner] Finished performing jobs."
  rescue StandardError => e
    puts "[JobRunner] Error during perform_jobs: #{e.message}"
    Rails.logger.error "[JobRunner] Error during perform_jobs: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e # Re-raise the error so the command execution likely fails
  end
end

# Instantiate the runner and execute the jobs
JobRunner.new.perform_jobs
