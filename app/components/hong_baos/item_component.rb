# frozen_string_literal: true

class HongBaos::ItemComponent < ViewComponent::Base
  with_collection_parameter :envelope

  def initialize(envelope:, featured: false, position: nil)
    @envelope = envelope
    @featured = featured
    @position = position
    super()
  end

  private

  attr_reader :envelope, :featured, :position

  def wrapper_classes
    base_classes = "transform transition-all duration-300"
    "#{base_classes} scale-90 md:scale-100 opacity-75 hover:scale-110"
  end

  def image_classes
    "w-64 md:w-72"
  end

  def logo_size_classes
    "w-8 h-8"
  end

  def logo_text_size
    "text-sm"
  end

  def title_size
    "text-sm"
  end

  def subtitle_size
    "text-xs"
  end

  def padding_classes
    "p-4"
  end
end
