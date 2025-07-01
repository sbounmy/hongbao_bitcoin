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
      puts "--> Setting up #{count} parallel test databases..."
      system("bundle exec rake parallel:create[#{count}] parallel:prepare[#{count}] RAKE_ENV=test") or raise "Failed to set up parallel databases."

      puts "--> Starting #{count} foreman instances..."
      1.upto(count) do |i|
        foreman_port = base_foreman_port + ((i - 1) * 100)
        env_number = i == 1 ? "" : i

        # Set WEB_PORT so the stripe process knows where to forward to.
        # Foreman will correctly assign foreman_port to the web process's $PORT.
        foreman_cmd = "APP_PORT=#{foreman_port} TEST_ENV_NUMBER=#{env_number} foreman start -f Procfile.test"
        foreman_pids << Process.spawn(foreman_cmd, out: "/dev/null", err: "/dev/null")

        # # Playwright connects to the port we know Foreman assigned to the web process.
        # base_url = "http://localhost:#{foreman_port}"
        # playwright_cmd = "E2E_PARALLEL_RUN=true BASE_URL=#{base_url} npx playwright test --shard=#{i}/#{count}"
        # playwright_pids << Process.spawn(playwright_cmd)
        # puts "  - Started foreman (base port: #{foreman_port}) and Playwright for shard #{i}"
      end

      sleep 15 # Wait for the puma server to boot

      1.upto(count) do |i|
        foreman_port = base_foreman_port + ((i - 1) * 100)
        env_number = i == 1 ? "" : i

        base_url = "http://localhost:#{foreman_port}"
        playwright_cmd = "E2E_PARALLEL_RUN=true BASE_URL=#{base_url} npx playwright test --shard=#{i}/#{count}"
        playwright_pids << Process.spawn(playwright_cmd)
        puts "  - Started foreman (base port: #{foreman_port}) and Playwright for shard #{i}"
      end

      puts "--> Waiting for Playwright tests to complete..."
      playwright_pids.each { |pid| Process.wait(pid) }
      puts "--> Playwright tests finished."

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
