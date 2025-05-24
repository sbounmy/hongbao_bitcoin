class DiffComponent < ApplicationComponent
  renders_one :before
  renders_one :after

  def initialize(options = {})
    @class = options[:class]
  end
end
