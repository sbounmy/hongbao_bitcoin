class DrawerComponent < ApplicationComponent
  renders_one :body
  renders_one :label

  def initialize(id:, **options)
    @id = id
    @options = options
  end

  def html_class
    "drawer mr-4 sm:mr-0 #{options[:class]}"
  end

  def z_class
    "z-#{options[:z]}" if options[:z]
  end

  private

  attr_reader :id, :options
end
