class ClipboardComponent < ApplicationComponent
  renders_one :input
  def initialize(text: nil, label: nil, **options)
    @text = text
    @label = label
    @options = options
  end
end
