class Ai::Images::Done < ApplicationService
  def call(params)
    @image.update!(status: "done")
  end
end
