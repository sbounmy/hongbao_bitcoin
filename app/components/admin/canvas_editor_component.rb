# frozen_string_literal: true

module Admin
  class CanvasEditorComponent < ApplicationComponent
    attr_reader :form, :object, :input_base_name

    def initialize(form:, input_base_name:)
      @form = form
      @object = form.object
      @input_base_name = input_base_name
      super()
    end

    delegate :image_back, :image_front, to: :object

    def elements_json
      object.elements.to_json
    end

    def front_image_url
      return nil unless image_front.attached?
      Rails.application.routes.url_helpers.url_for(image_front)
    end

    def back_image_url
      return nil unless image_back.attached?
      Rails.application.routes.url_helpers.url_for(image_back)
    end

    def frame
      object.respond_to?(:frame_object) ? object.frame_object : Frame.new("landscape")
    end

    # Sample wallet data for placeholder visualization in admin editor
    def sample_wallet_data
      {
        mnemonic_text: "abandon ability able about above absent absorb abstract absurd abuse access accident",
        private_key_text: "L4rK1yDtCWekvXuE6oXD9jCYfFNV2cWRpVuPLBcCU2z8TrisoyY1",
        public_address_text: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
        public_address_qrcode: sample_qr_base64("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"),
        private_key_qrcode: sample_qr_base64("L4rK1yDtCWekvXuE6oXD9jCYfFNV2cWRpVuPLBcCU2z8TrisoyY1")
      }.to_json
    end

    def sample_qr_base64(text)
      qr = RQRCode::QRCode.new(text)
      png = qr.as_png(
        bit_depth: 1,
        border_modules: 4,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: "black",
        fill: "white",
        resize_exactly_to: 200
      )
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    end
  end
end
