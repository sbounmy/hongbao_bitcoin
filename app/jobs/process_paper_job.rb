require "stringio"
require "vips"
# Assuming Faraday is required elsewhere or autoloaded

class ProcessPaperJob < ApplicationJob
  queue_as :default

  def perform(message_id, quality: "high")
    @message = Message.find(message_id)
    @paper = @message.paper
    @chat = @message.chat
    theme_attachment = nil
    image_attachment = nil
    prepared_theme = nil
    prepared_image = nil

    begin
      input_items = @chat.input_items.includes(input: { image_attachment: :blob }) # Eager load
      theme_input = input_items.find { |item| item.input.type == "Input::Theme" }&.input
      image_input = input_items.find { |item| item.input.type == "Input::Image" }

      theme_attachment = theme_input&.image
      image_attachment = image_input&.image

      Rails.logger.info "[RubyLLM] #{quality} Chat #{@chat.id} with prompt, theme, and image."
      # 5. Call the LLM service
      response = RubyLLM.edit(
        @message.content,
        model: "gpt-image-1",
        with: { image: [ path_for(theme_attachment), path_for(image_attachment) ] },
        options: {
          size: "1024x1024",
          quality:,
          user: @message.user_id
        }
      )

      Rails.logger.info "Response: #{response.usage.inspect}"

      @paper.image_full.attach(io: StringIO.new(response.to_blob), filename: "full_#{SecureRandom.hex(4)}.jpg")
      @paper.save!

      @message.update!(
        input_tokens: response.usage["input_tokens"],
        output_tokens: response.usage["output_tokens"],
        input_image_tokens: response.usage.dig("input_tokens_details", "image_tokens"),
        input_text_tokens: response.usage.dig("input_tokens_details", "text_tokens"),
        total_tokens: response.usage["total_tokens"],
        total_costs: response.total_cost,
        input_costs: response.input_cost,
        output_costs: response.output_cost,
      )

      top, bottom = split_image(response.to_blob)

      Rails.logger.info "Attaching generated image to Paper for Chat #{@chat.id}."
      @paper.image_front.attach(io: top, filename: "front_#{SecureRandom.hex(4)}.jpg")
      @paper.image_back.attach(theme_input.back_image.blob)
      @paper.save!
      Rails.logger.info "Successfully saved Paper #{@paper.id} for Chat #{@chat.id}."

    rescue => e
      puts "Error during job for Chat #{@chat.id}: #{e.message}"
      puts e.backtrace.join("\n")
      # Handle error (e.g., update chat status, retry job)
    ensure
      # 7. CRITICAL: Ensure cleanup for both attachments
      puts "Ensuring cleanup for Chat #{@chat.id}..."
      prepared_theme&.cleanup
      prepared_image&.cleanup
    end
  end

  private

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

  def path_for(attachment)
    ActiveStorage::Blob.service.path_for(attachment.key)
  end
end
