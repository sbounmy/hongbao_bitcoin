class FieldsetComponent < ApplicationComponent
  renders_one :input
  renders_one :badge
  renders_one :note
  renders_one :icon
  attr_reader :name, :label, :options, :label_class

  def initialize(name, label:, **options)
    @name = name
    @label = label
    @options = options
    @label_class = options[:label_class] || "input w-full bg-transparent border-white/10 text-white"
  end



  def attributes
    {
      class: "fieldset relative",
      "data-controller": "clipboard",
      "data-clipboard-success-content-value": "Copied!"
    }
  end
end
