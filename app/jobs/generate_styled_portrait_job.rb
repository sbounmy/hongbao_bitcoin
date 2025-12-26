class GenerateStyledPortraitJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(input_item_id)
    @input_item = InputItem.find(input_item_id)
    @style = @input_item.input

    return unless @style.is_a?(Input::Style)
    return unless @input_item.image.attached?

    Rails.logger.info "[GenerateStyledPortraitJob] Processing InputItem #{@input_item.id} with style #{@style.name}"

    generate_and_attach_portrait
    broadcast_result

    Rails.logger.info "[GenerateStyledPortraitJob] Successfully generated styled portrait for InputItem #{@input_item.id}"
  end

  private

  def generate_and_attach_portrait
    base_config = Input::Configuration.instance
    full_prompt = [base_config.prompt, @style.prompt].compact_blank.join(". ")

    Rails.logger.info "[GenerateStyledPortraitJob] Using prompt: #{full_prompt}"

    styled_response = Papers::StyleGenerator.call(
      portrait: @input_item.image,
      prompt: full_prompt,
      quality: "high"
    )

    @input_item.generated_image.attach(
      io: StringIO.new(styled_response.to_blob),
      filename: "generated_#{@style.slug}_#{SecureRandom.hex(4)}.png"
    )

    @input_item.save!
  end

  def broadcast_result
    url = rails_blob_path(@input_item.generated_image, only_path: true)
    user = @input_item.user || @input_item.paper&.user

    return unless user

    Rails.logger.info "[GenerateStyledPortraitJob] Broadcasting image:generated to user #{user.id} with url: #{url}"

    # Broadcast to user's AI generation channel (subscription exists on page load)
    Turbo::StreamsChannel.broadcast_action_to(
      [user, :ai_generation],
      action: :dispatch,
      target: "image",
      attributes: {
        event: "image:generated",
        detail: { url: url }.to_json
      }
    )

    Rails.logger.info "[GenerateStyledPortraitJob] Broadcast complete for user #{user.id}"
  end
end
