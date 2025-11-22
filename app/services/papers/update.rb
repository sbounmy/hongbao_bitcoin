require "stringio"

module Papers
  class Update < ApplicationService
    def call(paper:, theme_id:)
      # Find new theme
      new_theme = Input::Theme.find(theme_id)

      # Update paper's theme using the new association
      if paper.input_item_theme
        paper.input_item_theme.update!(input: new_theme)
      else
        # Create if doesn't exist
        paper.create_input_item_theme!(input: new_theme)
      end

      # Only re-compose if portrait is already generated
      if paper.image_portrait.attached?
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
        paper.save!  # Name will be updated automatically by before_save callback
      end
      paper
    end
  end
end
