module GitInfo
  class << self
    def commit_hash
      ENV.fetch("COMMIT_SHA", "development")
    end

    def commit_time
      ENV.fetch("COMMIT_TIME", Time.current.to_s)
    end
  end
end
