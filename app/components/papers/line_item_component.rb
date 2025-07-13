# frozen_string_literal: true

module Papers
  class LineItemComponent < ApplicationComponent
    with_collection_parameter :paper
    attr_reader :paper

    def initialize(paper:)
      @paper = paper
      super
    end

    private

    def image_front_url
      return "" unless paper.image_front.attached?

      url_for(paper.image_front)
    end

    def creator_name
      # NOTE: Assuming `paper` has a `user` association.
      "Anonymous"
    end

    def creator_avatar_url
      # NOTE: Assuming `user` has an `avatar` attached.
      return unless paper.user&.avatar&.attached?

      url_for(paper.user.avatar)
    end

    def paper_genres
      # NOTE: Assuming `paper` has a `style` attribute.
      paper.style.presence || "No style defined"
    end

    def theme_version
      # NOTE: Assuming `paper` has a `theme` with a `version`.
      paper.theme&.version
    end

    # NOTE: The following stats are placeholders to match the design.
    # The `Paper` model does not have these attributes yet.
    def play_count
      "5.5K"
    end

    def like_count
      "130"
    end

    def comment_count
      "19"
    end
  end
end
