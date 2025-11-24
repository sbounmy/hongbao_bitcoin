require "stringio"

module Papers
  class Update < ApplicationService
    def call(paper:, params:)
      # Assign attributes without saving (to avoid premature broadcasting)
      paper.assign_attributes(params)

      # Get the updated theme
      new_theme = paper.theme

      # Only re-compose if portrait is already generated and theme exists
      if new_theme && paper.image_portrait.attached?
        # Re-compose with new theme
        composed_image = Papers::Composition.call(
          template: new_theme.image_front,
          portrait: paper.image_portrait.blob.download,
          config: new_theme.portrait_config
        )

        # Update front image
        paper.image_front.attach(
          io: StringIO.new(composed_image),
          filename: "front_#{SecureRandom.hex(4)}.jpg"
        )

        # Update back image
        paper.image_back.attach(new_theme.image_back.blob) if new_theme.image_back.attached?
        paper.elements = new_theme.ai
      end

      # Save once at the end - this triggers the broadcast with all changes
      paper.save!
      paper
    end
  end
end
