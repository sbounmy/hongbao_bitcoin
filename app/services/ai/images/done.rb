require "open-uri"
require "vips"

class Ai::Images::Done < ApplicationService
  attr_reader :params
  def call(params)
    @params = params

    update_images
    create_papers
  end

  private

  def update_images
    image.response_image_urls = image_urls
    image.save!
    image_urls.each do |url|
      downloaded_image = URI.parse(url).open
      image.images.attach(io: downloaded_image, filename: "#{SecureRandom.hex(8)}.jpg")
    end
  end

  def create_papers
    image.images.each do |attached_image|
      top, bottom = split_image(attached_image.download)

      paper = Paper.new(
        name: "Generated Paper #{SecureRandom.hex(4)}",
        active: true,
        public: false,
        user: image.user
      )

      paper.image_front.attach(io: top, filename: "front_#{SecureRandom.hex(4)}.jpg")
      paper.image_back.attach(io: bottom, filename: "back_#{SecureRandom.hex(4)}.jpg")

      paper.save!
    end
    image.complete!
  end

  def split_image(binary_data)
    # Load image with Vips directly
    vips_image = Vips::Image.new_from_buffer(binary_data, "")
    width = vips_image.width
    height = vips_image.height

    # Extract top and bottom halves
    top_half = vips_image.crop(0, 0, width, height / 2)
    bottom_half = vips_image.crop(0, height / 2, width, height / 2)

    # Convert to PNG format and get binary data
    top_data = top_half.write_to_buffer(".jpg")
    bottom_data = bottom_half.write_to_buffer(".jpg")

    [ StringIO.new(top_data), StringIO.new(bottom_data) ]
  end

  def image_urls
    params.dig("data", "object", "images").map { |img| img["url"] }
  end

  def image
    @image ||= Ai::Image.find_by(external_id: params.dig("data", "object", "id"))
  end
end
