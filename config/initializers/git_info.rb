module GitInfo
  class << self
    def commit_hash
      @commit_hash ||= `git rev-parse --short HEAD`.chomp
    end

    def commit_time
      @commit_time ||= `git show -s --format=%ci HEAD`.chomp
    end
  end
end
