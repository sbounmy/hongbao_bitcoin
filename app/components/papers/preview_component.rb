module Papers
  class PreviewComponent < ApplicationComponent
    def initialize(paper:, size: :default)
      @paper = paper
      @size = size
    end

    private

    attr_reader :paper, :size

    def processing?
      paper.processing?
    end

    def image_url
      return nil unless paper.image_front.attached?

      rails_blob_url(paper.image_front)
    end

    def container_classes
      case size
      when :small
        "max-w-sm max-h-[50vh]"
      when :large
        "max-w-4xl max-h-[90vh]"
      else
        "max-w-full max-h-[70vh] md:max-h-full"
      end
    end

    def image_classes
      "max-w-full max-h-full object-contain rounded-lg shadow-2xl"
    end

    def placeholder_classes
      case size
      when :small
        "w-64 h-64"
      when :large
        "w-[600px] h-[600px]"
      else
        "w-96 h-96"
      end
    end
  end
end