# frozen_string_literal: true

class V3::ColorButtonComponent < ApplicationComponent
  attr_reader :color, :label, :selected

  def initialize(color:, label:, selected: false)
    @color = color
    @label = label
    @selected = selected
    super()
  end

  # Helper to format the color for the radio button's value
  def color_value
    color.is_a?(Array) ? color.join(",") : color.to_s
  end

  # Generate a unique ID for the radio button and its label
  def radio_id
    "color_radio_#{color_value.parameterize}"
  end

  def classes
    [
      "block w-16 h-16 rounded-full border-2 shadow-md cursor-pointer flex-shrink-0",
      "focus:outline-none transition-transform transform hover:scale-110",
      "peer-focus:ring-2 peer-focus:ring-offset-2",
      color_classes,
      selected ? COLOR_MAP[color.is_a?(Array) ? color.first : color][:selected]  : "border-white"
    ].join(" ")
  end

  private
  COLOR_MAP = {
    red:    { selected: "border-red-300 ring-2 ring-red-300", bg: "bg-red-500", from: "from-red-500", to: "to-red-500", ring: "peer-focus:ring-red-500" },
    orange: { selected: "border-orange-300 ring-2 ring-orange-300", bg: "bg-orange-500", from: "from-orange-500", to: "to-orange-500", ring: "peer-focus:ring-orange-500" },
    amber:  { selected: "border-amber-300 ring-2 ring-amber-300", bg: "bg-amber-500", from: "from-amber-500", to: "to-amber-500", ring: "peer-focus:ring-amber-500" },
    yellow: { selected: "border-yellow-300 ring-2 ring-yellow-300", bg: "bg-yellow-500", from: "from-yellow-500", to: "to-yellow-500", ring: "peer-focus:ring-yellow-500" },
    lime:   { selected: "border-lime-300 ring-2 ring-lime-300", bg: "bg-lime-500", from: "from-lime-500", to: "to-lime-500", ring: "peer-focus:ring-lime-500" },
    green:  { selected: "border-green-500 ring-2 ring-green-300", bg: "bg-green-500", from: "from-green-500", to: "to-green-500", ring: "peer-focus:ring-green-500" },
    emerald: { selected: "border-emerald-300 ring-2 ring-emerald-300", bg: "bg-emerald-500", from: "from-emerald-500", to: "to-emerald-500", ring: "peer-focus:ring-emerald-500" },
    teal:   { selected: "border-teal-300 ring-2 ring-teal-300", bg: "bg-teal-500", from: "from-teal-500", to: "to-teal-500", ring: "peer-focus:ring-teal-500" },
    cyan:   { selected: "border-cyan-300 ring-2 ring-cyan-300", bg: "bg-cyan-500", from: "from-cyan-500", to: "to-cyan-500", ring: "peer-focus:ring-cyan-500" },
    sky:    { selected: "border-sky-300 ring-2 ring-sky-300", bg: "bg-sky-500", from: "from-sky-500", to: "to-sky-500", ring: "peer-focus:ring-sky-500" },
    blue:   { selected: "border-blue-300 ring-2 ring-blue-300", bg: "bg-blue-500", from: "from-blue-500", to: "to-blue-500", ring: "peer-focus:ring-blue-500" },
    indigo: { selected: "border-indigo-300 ring-2 ring-indigo-300", bg: "bg-indigo-500", from: "from-indigo-500", to: "to-indigo-500", ring: "peer-focus:ring-indigo-500" },
    violet: { selected: "border-violet-300 ring-2 ring-violet-300", bg: "bg-violet-500", from: "from-violet-500", to: "to-violet-500", ring: "peer-focus:ring-violet-500" },
    purple: { selected: "border-purple-300 ring-2 ring-purple-300", bg: "bg-purple-500", from: "from-purple-500", to: "to-purple-500", ring: "peer-focus:ring-purple-500" },
    fuchsia: { selected: "border-fuchsia-300 ring-2 ring-fuchsia-300", bg: "bg-fuchsia-500", from: "from-fuchsia-500", to: "to-fuchsia-500", ring: "peer-focus:ring-fuchsia-500" },
    pink:   { selected: "border-pink-300 ring-2 ring-pink-300", bg: "bg-pink-500", from: "from-pink-500", to: "to-pink-500", ring: "peer-focus:ring-pink-500" },
    rose:   { selected: "border-rose-300 ring-2 ring-rose-300", bg: "bg-rose-500", from: "from-rose-500", to: "to-rose-500", ring: "peer-focus:ring-rose-500" }
  }.freeze

  def color_classes
    if color.is_a?(Array)
      dynamic_split_class
    else
      classes = COLOR_MAP[color]
      classes ? "#{classes[:bg]} #{classes[:ring]}" : "bg-gray-400 peer-focus:ring-gray-400"
    end
  end

  def dynamic_split_class
    color1_sym, color2_sym = color
    c1 = COLOR_MAP[color1_sym]
    c2 = COLOR_MAP[color2_sym]

    return "bg-gray-400 peer-focus:ring-gray-400" unless c1 && c2

    "bg-gradient-to-r #{c1[:from]} from-50% #{c2[:to]} to-50% #{c1[:ring]}"
  end
end
