require "stringio"

module Papers
  class Update < ApplicationService
    def call(paper:, params:)
      # Assign attributes without saving (to avoid premature broadcasting)
      paper.assign_attributes(params)

      # Get the updated theme
      new_theme = paper.theme

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
      paper.image_front.analyze # save + so attach is sync for broadcast https://stackoverflow.com/questions/61309182/how-to-force-activestorageattachedattach-to-run-synchronously-disable-asyn#comment134359695_65619420
      paper
    end
  end
end
