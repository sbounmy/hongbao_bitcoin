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
    red:    "bg-red-500 focus:ring-red-500",
    orange: "bg-orange-500 focus:ring-orange-500",
    amber:  "bg-amber-500 focus:ring-amber-500",
    yellow: "bg-yellow-500 focus:ring-yellow-500",
    lime:   "bg-lime-500 focus:ring-lime-500",
    green:  "bg-green-500 focus:ring-green-500",
    emerald: "bg-emerald-500 focus:ring-emerald-500",
    teal:   "bg-teal-500 focus:ring-teal-500",
    cyan:   "bg-cyan-500 focus:ring-cyan-500",
    sky:    "bg-sky-500 focus:ring-sky-500",
    blue:   "bg-blue-500 focus:ring-blue-500",
    indigo: "bg-indigo-500 focus:ring-indigo-500",
    violet: "bg-violet-500 focus:ring-violet-500",
    purple: "bg-purple-500 focus:ring-purple-500",
    fuchsia: "bg-fuchsia-500 focus:ring-fuchsia-500",
    pink:   "bg-pink-500 focus:ring-pink-500",
    rose:   "bg-rose-500 focus:ring-rose-500"
  }.freeze

  def color_classes
    if color == :split
      dynamic_split_class
    else
      COLOR_MAP[color] || "bg-gray-400 focus:ring-gray-400" # if color doesnt exist.
    end
  end
end
