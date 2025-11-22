module MobileHeader
  class ActionComponent < ApplicationComponent
    def initialize(content:, href:, method: :get, **options)
      @content = content
      @href = href
      @method = method
      @options = options
    end

    private

    attr_reader :content, :href, :method, :options

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