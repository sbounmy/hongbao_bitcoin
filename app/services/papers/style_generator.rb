module Papers
  class StyleGenerator < ApplicationService
    def call(portrait:, prompt:, quality: "high", resolution: "1024x1024")
      @portrait = portrait
      @prompt = prompt
      @quality = quality
      @resolution = resolution

      generate_styled_portrait
    end

    private

    def generate_styled_portrait
      portrait_path = ActiveStorage::Blob.service.path_for(@portrait.key)

      Rails.logger.info "[Papers::StyleGenerator] Transforming portrait with style: #{@prompt[0..50]}..."
      Rails.logger.info "[Papers::StyleGenerator] Resolution: #{@resolution}"

      # Call AI to transform portrait into style
      response = RubyLLM.edit(
        @prompt,
        model: "gpt-image-1",
        with: { image: portrait_path },
        options: {
          background: 'transparent',
          size: @resolution,
          quality: @quality
        }
      )

      Rails.logger.info "[Papers::StyleGenerator] Transformation complete. Usage: #{response.usage.inspect}"

      response
    end
  end
end
