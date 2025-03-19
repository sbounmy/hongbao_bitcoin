class Ai::Images::Done < ApplicationService
  def initialize(image_id)
    @image = Ai::Image.find(image_id)
  end

  def call
    @image.update!(status: "done")
  end
end
