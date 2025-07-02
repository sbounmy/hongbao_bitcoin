namespace :e2e do
  desc "Run Playwright tests in parallel"
  task :parallel, [ :count ] do |_, args|
    count = (args[:count] || 4).to_i
    # Each foreman instance gets its own base port. Foreman assigns the
    # base port to the first process in the Procfile (web).
    base_foreman_port = 5100
    foreman_pids = []
    playwright_pids = []

    begin
      puts "--> Cleaning up old reports..."
      system("rm -rf ./blob-reports")
      system("rm -rf ./playwright-report")

      puts "--> Setting up #{count} parallel test databases..."
      system("bundle exec rake parallel:create[#{count}] parallel:prepare[#{count}] RAKE_ENV=test") or raise "Failed to set up parallel databases."

      puts "--> Starting #{count} foreman instances..."
      1.upto(count) do |i|
        foreman_port = base_foreman_port + ((i - 1) * 100)

        # Set WEB_PORT so the stripe process knows where to forward to.
        # Foreman will correctly assign foreman_port to the web process's $PORT.
        foreman_cmd = "APP_PORT=#{foreman_port} TEST_ENV_NUMBER=#{i} foreman start -f Procfile.test"
        foreman_pids << Process.spawn(foreman_cmd)

        # # Playwright connects to the port we know Foreman assigned to the web process.
        # base_url = "http://localhost:#{foreman_port}"
        # playwright_cmd = "E2E_PARALLEL_RUN=true BASE_URL=#{base_url} npx playwright test --shard=#{i}/#{count}"
        # playwright_pids << Process.spawn(playwright_cmd)
        # puts "  - Started foreman (base port: #{foreman_port}) and Playwright for shard #{i}"
      end

      sleep 15 # Wait for the puma server to boot

      1.upto(count) do |i|
        foreman_port = base_foreman_port + ((i - 1) * 100)

        base_url = "http://localhost:#{foreman_port}"
        output_dir = "./blob-reports/shard-#{i}"
        playwright_cmd = "E2E_PARALLEL_RUN=true BASE_URL=#{base_url} PLAYWRIGHT_BLOB_OUTPUT_DIR=#{output_dir} npx playwright test --shard=#{i}/#{count}"
        playwright_pids << Process.spawn(playwright_cmd)
        puts "  - Started foreman (base port: #{foreman_port}) and Playwright for shard #{i}"
      end

      puts "--> Waiting for Playwright tests to complete..."
      statuses = playwright_pids.map do |pid|
        _pid, status = Process.wait2(pid)
        status
      end
      puts "--> Playwright tests finished. #{statuses.inspect}"

      # Give a moment for all the report files to be written to the disk.
      # This helps prevent a race condition where the merge starts before all files are ready.
      sleep 5

      failed_shards = statuses.select { |s| !s.success? }
      if failed_shards.any?
        puts "--> #{failed_shards.size}/#{playwright_pids.size} Playwright shards failed."
      end

      puts "--> Merging reports..."
      # The merge-reports command will create the playwright-report directory.
      system("rm -rf ./blob-reports/*.zip")
      system("cp ./blob-reports/*/*.zip ./blob-reports/")
      system("npx playwright merge-reports --reporter html ./blob-reports")
      puts "--> Reports merged into 'playwright-report' directory."

      if failed_shards.any?
        raise "One or more Playwright shards failed."
      end

    ensure
      puts "--> Cleaning up..."
      if foreman_pids.any?
        puts "--> Stopping foreman processes..."
        foreman_pids.each do |pid|
          begin
            # Kill the entire process group foreman creates
            Process.kill("-TERM", pid)
            puts "  - Killed foreman group with PID #{pid}"
          rescue Errno::ESRCH
            puts "  - Foreman group with PID #{pid} was already stopped."
          end
        end
        Process.waitall
      end
      puts "--> Done."
    end
  end
end
