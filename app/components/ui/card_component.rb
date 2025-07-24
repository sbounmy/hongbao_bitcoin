# frozen_string_literal: true

module Ui
  class CardComponent < ApplicationComponent
    renders_one :figure, "Ui::FigureComponent"
    renders_one :title
    renders_one :actions
    renders_one :body

    def initialize(
      image_full: false,
      compact: false,
      side: false,
      glass: false,
      bordered: false,
      normal: false,
      figure_position: :top, # :top or :bottom
      **options
    )
      @image_full = image_full
      @compact = compact
      @side = side
      @glass = glass
      @bordered = bordered
      @normal = normal
      @figure_position = figure_position
      @options = options
    end

    private

    attr_reader :figure_position

    def card_classes
      classes = [ "card" ]
      classes << "bg-base-100" unless @glass
      classes << "image-full" if @image_full
      classes << "card-compact" if @compact
      classes << "card-side" if @side
      classes << "glass" if @glass
      classes << "card-bordered" if @bordered
      classes << "card-normal" if @normal
      classes << "shadow-xl" unless @options[:shadow] == false
      classes << @options[:class] if @options[:class]
      classes.compact.join(" ")
    end

    def html_attributes
      @options.except(:class, :shadow).merge(class: card_classes)
    end
  end

  class FigureComponent < ApplicationComponent
    def initialize(overlay: false, **options)
      @overlay = overlay
      @options = options
    end

    def call
      content_tag(:figure, content, **html_attributes)
    end

    private

    def html_attributes
      classes = []
      classes << @options[:class] if @options[:class]
      @options.except(:class).merge(class: classes.compact.join(" "))
    end
  end
end
