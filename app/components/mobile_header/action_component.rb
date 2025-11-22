module MobileHeader
  class ActionComponent < ApplicationComponent
    def initialize(icon:, href:, method: :get, **options)
      @icon = icon
      @href = href
      @method = method
      @options = options
    end

    private

    attr_reader :icon, :href, :method, :options

    def link_options
      options.merge(
        class: "inline-flex items-center justify-center w-10 h-10 -mr-2"
      )
    end

    def button?
      method != :get
    end
  end
end