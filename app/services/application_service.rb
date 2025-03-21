class ApplicationService
  class ErrorService
    def self.error(exception, options = {})
      puts "Error: #{exception.message}"
      puts "Options: #{options.inspect}"
    end
  end

  Response = Struct.new(:success?, :payload, :error) do
    def failure?
      !success?
    end
  end

  def initialize(propagate = true)
    @propagate = propagate
  end

  def self.call(...)
    service = new(false)
    service.call(...)
  rescue StandardError => e
    service.failure(e)
  end

  def self.call!(...)
    new(true).call(...)
  end

  def success(payload = nil)
    Response.new(true, payload)
  end

  def failure(exception, options = {})
    raise exception if @propagate

    ErrorService.error(exception, options)
    Response.new(false, nil, exception)
  end

  def credentials(*keys)
    Rails.application.credentials.dig(*keys)
  end
end
