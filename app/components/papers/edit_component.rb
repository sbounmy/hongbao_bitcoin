module Papers
  class EditComponent < ApplicationComponent
    def initialize(paper:)
      @paper = paper
    end

    private

    attr_reader :paper

    def processing?
      paper.processing?
    end

    def image_url
      return nil unless paper.image_front.attached?

      rails_blob_url(paper.image_front)
    end

    def image_classes
      "max-w-full max-h-full object-contain rounded-lg shadow-2xl"
    end
  end
end
