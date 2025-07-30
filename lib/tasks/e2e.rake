require "socket"

namespace :e2e do
  desc "Run Playwright tests in parallel"
  task :parallel, [ :count, :file ] do |_, args|
    count = (args[:count] || 4).to_i
    file = args[:file]
    # Each foreman instance gets its own base port. Foreman assigns the
    # base port to the first process in the Procfile (web).
    base_foreman_port = 5100
    foreman_pids = []
    playwright_pids = []

    # Determine if we're in CI and should reduce output
    is_ci = ENV["CI"] == "true"
    reporter = is_ci ? "--reporter=dot" : "--reporter=list"
    foreman_output = is_ci ? "/dev/null" : :out

    # Helper method to handle CI-aware output
    log_section = lambda do |title, is_end = false|
      if is_end && is_ci
        puts "::endgroup::"
      elsif is_ci
        puts "::group::#{title}"
      elsif !is_end && title
        puts "--> #{title}..."
      end
    end

    begin
      log_section.call("Cleaning up old reports")
      system("rm -rf ./blob-reports")
      system("rm -rf ./playwright-report")
      log_section.call(nil, true)

      log_section.call("Setting up #{count} parallel test databases")
      system("bundle exec rake parallel:create[#{count}] parallel:migrate[#{count}] RAKE_ENV=test#{is_ci ? ' > /dev/null 2>&1' : ''}") or raise "Failed to set up parallel databases."
      log_section.call(nil, true)

      log_section.call("Starting #{count} foreman instances")
      1.upto(count) do |i|
        foreman_port = base_foreman_port + ((i - 1) * 100)

        env = { "APP_PORT" => foreman_port.to_s, "TEST_ENV_NUMBER" => i.to_s }

        if ENV["GITHUB_RUN_ID"].present?
          env["STRIPE_CONTEXT_ID"] = "test_run_#{ENV['GITHUB_RUN_ID']}_shard_#{i}"
        else
          # Fallback for local execution
          env["STRIPE_CONTEXT_ID"] = "dev_#{Socket.gethostname.split(".").first}_shard_#{i}"
        end

        foreman_pids << Process.spawn(
          env,
          "foreman", "start", "-f", "Procfile.test",
          out: foreman_output,
          err: foreman_output,
          pgroup: true
        )
      end
      log_section.call(nil, true)

      sleep 15 # Wait for the puma server to boot

      log_section.call("Running Playwright tests on #{count} shards")
      1.upto(count) do |i|
        foreman_port = base_foreman_port + ((i - 1) * 100)

        base_url = "http://localhost:#{foreman_port}"
        output_dir = "./blob-reports/shard-#{i}"
        playwright_cmd = "E2E_PARALLEL_RUN=true BASE_URL=#{base_url} PLAYWRIGHT_BLOB_OUTPUT_DIR=#{output_dir} npx playwright test #{file} #{reporter} --shard=#{i}/#{count}"
        playwright_pids << Process.spawn(playwright_cmd)
        puts "  - Started shard #{i} (port: #{foreman_port})"
      end
      log_section.call(nil, true)

      puts "--> Waiting for Playwright tests to complete..."
      statuses = playwright_pids.map do |pid|
        _pid, status = Process.wait2(pid)
        status
      end

      unless is_ci
        puts "--> Playwright tests finished. #{statuses.inspect}"
      end

      # Give a moment for all the report files to be written to the disk.
      # This helps prevent a race condition where the merge starts before all files are ready.
      sleep 5

      failed_shards = statuses.each_with_index.select { |s, _| !s.success? }.map { |_, i| i + 1 }
      if failed_shards.any?
        if is_ci
          puts "::error::#{failed_shards.size}/#{count} Playwright shards failed (shards: #{failed_shards.join(', ')})"
        else
          puts "--> #{failed_shards.size}/#{playwright_pids.size} Playwright shards failed."
        end
      else
        puts "✅ All #{count} shards passed successfully"
      end

      log_section.call("Merging test reports")
      # Remove any existing zip files from the blob-reports directory
      system("rm -rf ./blob-reports/*.zip")
      # Copy the zip files from the shard directories to the blob-reports directory
      system("cp ./blob-reports/*/*.zip ./blob-reports/")
      # Merge the reports
      # The merge-reports command will create the playwright-report directory.
      # Don't suppress merge-reports output completely as it needs to create the directory
      merge_success = system("npx playwright merge-reports --reporter html ./blob-reports")
      if merge_success
        puts "--> Reports merged into 'playwright-report' directory."
      else
        puts "::error::Failed to merge playwright reports"
      end
      log_section.call(nil, true)

      if failed_shards.any?
        raise "One or more Playwright shards failed."
      end

    ensure
      log_section.call("Cleaning up")
      if foreman_pids.any?
        puts "--> Stopping foreman processes..."
        foreman_pids.each_with_index do |pid, i|
          begin
            # Kill the entire process group foreman creates.
            # The negative PID sends the signal to the entire process group.
            Process.kill("TERM", -pid)
            puts "  - Stopped shard #{i + 1}"
          rescue Errno::ESRCH
            # Process already stopped
          end
        end
        Process.waitall
      end
      log_section.call(nil, true)
      puts "--> Done."
    end
  end
end
