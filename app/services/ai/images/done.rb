class Ai::Images::Done < ApplicationService
  attr_reader :params
  def call(params)
    @params = params

    update_images
    split_images
    create_papers
  end

  private

  def update_images
    image.response_image_urls = image_urls
    image.save!
  end

  def image_urls
    params.dig("data", "object", "images").map { |img| img["url"] }
  end

  def image
    @image ||= Ai::Image.find_by(external_id: params.dig("data", "object", "id"))
  end
end
