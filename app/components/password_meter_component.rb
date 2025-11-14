# frozen_string_literal: true

# PasswordMeterComponent - A reusable password strength meter component
# Provides visual feedback on password strength with configurable requirements
class PasswordMeterComponent < ApplicationComponent
  def initialize(
    input_id: nil,
    name: "password",
    placeholder: "8+ chars, uppercase, lowercase, number & symbol",
    data_targets: {},
    show_visibility_toggle: true,
    min_length: 8,
    max_length: 128,
    require_uppercase: true,
    require_lowercase: true,
    require_numbers: true,
    require_special: true,
    special_chars: "!@#$%^&*()_+-=[]{}|;:,.<>?",
    show_requirements: true,
    show_meter: true,
    compact: false,
    input_classes: "input input-bordered w-full pr-10 text-white placeholder-white/50 bg-[#F04747]/50 border-[#FFB636]/30"
  )
    @input_id = input_id || "password-#{SecureRandom.hex(4)}"
    @name = name
    @placeholder = placeholder
    @data_targets = data_targets
    @show_visibility_toggle = show_visibility_toggle
    @min_length = min_length
    @max_length = max_length
    @require_uppercase = require_uppercase
    @require_lowercase = require_lowercase
    @require_numbers = require_numbers
    @require_special = require_special
    @special_chars = special_chars
    @show_requirements = show_requirements
    @show_meter = show_meter
    @compact = compact
    @input_classes = input_classes
  end

  private

  attr_reader :input_id, :name, :placeholder, :data_targets, :show_visibility_toggle,
              :min_length, :max_length, :require_uppercase,
              :require_lowercase, :require_numbers, :require_special,
              :special_chars, :show_requirements, :show_meter, :compact, :input_classes

  def stimulus_values
    {
      "data-password-meter-min-length-value" => min_length,
      "data-password-meter-max-length-value" => max_length,
      "data-password-meter-require-uppercase-value" => require_uppercase,
      "data-password-meter-require-lowercase-value" => require_lowercase,
      "data-password-meter-require-numbers-value" => require_numbers,
      "data-password-meter-require-special-value" => require_special,
      "data-password-meter-special-chars-value" => special_chars
    }
  end

  def stimulus_classes
    {
      "data-password-meter-weak-class" => "bg-red-500",
      "data-password-meter-fair-class" => "bg-orange-500",
      "data-password-meter-strong-class" => "bg-yellow-500",
      "data-password-meter-very-strong-class" => "bg-green-500",
      "data-password-meter-requirement-met-class" => "text-green-400",
      "data-password-meter-requirement-unmet-class" => "text-white/60"
    }
  end

  def container_classes
    base = "password-meter"
    base += " password-meter--compact" if compact
    base
  end

  def meter_container_classes
    if compact
      "flex items-center gap-2"
    else
      "space-y-2"
    end
  end

  def requirements_container_classes
    if compact
      "hidden"
    else
      "space-y-1 text-xs mt-3"
    end
  end

  def requirement_classes
    "flex items-center gap-2 transition-colors duration-200 text-white/60"
  end
end
