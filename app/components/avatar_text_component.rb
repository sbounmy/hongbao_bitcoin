class AvatarTextComponent < ApplicationComponent
  attr_reader :text, :url, :image

  def initialize(text:, url:, image:)
    @text = text
    @url = url
    @image = image
  end
end