# frozen_string_literal: true

class V3::ColorButtonComponent < ApplicationComponent
  attr_reader :color, :label, :available_colors

  def initialize(color:, label:, available_colors: [])
    @color = color
    @label = label
    @available_colors = available_colors
    super()
  end

  def classes
    [
      "w-16 h-16 rounded-full border-2 border-white shadow-md focus:outline-none focus:ring-2 focus:ring-offset-2 transition-transform transform hover:scale-110",
      color_classes
    ].join(" ")
  end

  private
  COLOR_MAP = {
    red:    { bg: "bg-red-500", from: "from-red-500", to: "to-red-500", ring: "focus:ring-red-500" },
    orange: { bg: "bg-orange-500", from: "from-orange-500", to: "to-orange-500", ring: "focus:ring-orange-500" },
    amber:  { bg: "bg-amber-500", from: "from-amber-500", to: "to-amber-500", ring: "focus:ring-amber-500" },
    yellow: { bg: "bg-yellow-500", from: "from-yellow-500", to: "to-yellow-500", ring: "focus:ring-yellow-500" },
    lime:   { bg: "bg-lime-500", from: "from-lime-500", to: "to-lime-500", ring: "focus:ring-lime-500" },
    green:  { bg: "bg-green-500", from: "from-green-500", to: "to-green-500", ring: "focus:ring-green-500" },
    emerald: { bg: "bg-emerald-500", from: "from-emerald-500", to: "to-emerald-500", ring: "focus:ring-emerald-500" },
    teal:   { bg: "bg-teal-500", from: "from-teal-500", to: "to-teal-500", ring: "focus:ring-teal-500" },
    cyan:   { bg: "bg-cyan-500", from: "from-cyan-500", to: "to-cyan-500", ring: "focus:ring-cyan-500" },
    sky:    { bg: "bg-sky-500", from: "from-sky-500", to: "to-sky-500", ring: "focus:ring-sky-500" },
    blue:   { bg: "bg-blue-500", from: "from-blue-500", to: "to-blue-500", ring: "focus:ring-blue-500" },
    indigo: { bg: "bg-indigo-500", from: "from-indigo-500", to: "to-indigo-500", ring: "focus:ring-indigo-500" },
    violet: { bg: "bg-violet-500", from: "from-violet-500", to: "to-violet-500", ring: "focus:ring-violet-500" },
    purple: { bg: "bg-purple-500", from: "from-purple-500", to: "to-purple-500", ring: "focus:ring-purple-500" },
    fuchsia: { bg: "bg-fuchsia-500", from: "from-fuchsia-500", to: "to-fuchsia-500", ring: "focus:ring-fuchsia-500" },
    pink:   { bg: "bg-pink-500", from: "from-pink-500", to: "to-pink-500", ring: "focus:ring-pink-500" },
    rose:   { bg: "bg-rose-500", from: "from-rose-500", to: "to-rose-500", ring: "focus:ring-rose-500" }
  }.freeze

  def color_classes
    if color == :split
      dynamic_split_class
    else
      classes = COLOR_MAP[color]
      classes ? "#{classes[:bg]} #{classes[:ring]}" : "bg-gray-400 focus:ring-gray-400"
    end
  end

  def dynamic_split_class
    color1_sym = available_colors.first || :red
    color2_sym = available_colors.second || :orange

    c1 = COLOR_MAP[color1_sym]
    c2 = COLOR_MAP[color2_sym]

    return "bg-gray-400 focus:ring-gray-400" unless c1 && c2

    "bg-gradient-to-r #{c1[:from]} from-50% #{c2[:to]} to-50% #{c1[:ring]}"
  end
end
