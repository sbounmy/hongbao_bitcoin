require "stringio"
require "vips"
# Assuming Faraday is required elsewhere or autoloaded

class ProcessPaperJob < ApplicationJob
  queue_as :default

  def perform(paper_id, quality: "high")
    @paper = Paper.find(paper_id)

      # begin
      input_items = @paper.input_items
      theme_input = input_items.find { |item| item.input.type == "Input::Theme" }&.input
      image_input = input_items.find { |item| item.input.type == "Input::Image" }

      theme_attachment = theme_input&.image
      image_attachment = image_input&.image


      Rails.logger.info "[RubyLLM] #{quality} Paper #{@paper.id} with prompt, theme, and image."
      # 5. Call the LLM service
      response = RubyLLM.edit(
        @paper.prompt,
        model: "gpt-image-1",
        with: { image: [ path_for(theme_attachment), path_for(image_attachment) ] },
        options: {
          size: "1024x1024",
          quality:,
          user: @paper.user_id
        }
      )

      Rails.logger.info "Response: #{response.usage.inspect}"

      full_image = response.to_blob
      top = Papers::GapCorrector.call full_image

      # Convert PNG blobs to JPEG with vips
      full_image = Vips::Image.new_from_buffer(full_image, "").write_to_buffer(".jpg")
      top = Vips::Image.new_from_buffer(top, "").write_to_buffer(".jpg")

      @paper.image_full.attach(io: StringIO.new(full_image), filename: "full_#{SecureRandom.hex(4)}.jpg")

      @paper.assign_attributes(
        input_tokens: response.usage["input_tokens"],
        output_tokens: response.usage["output_tokens"],
        input_image_tokens: response.usage.dig("input_tokens_details", "image_tokens"),
        input_text_tokens: response.usage.dig("input_tokens_details", "text_tokens"),
        total_tokens: response.usage["total_tokens"],
        total_costs: response.total_cost,
        input_costs: response.input_cost,
        output_costs: response.output_cost,
      )

      @paper.save!


      Rails.logger.info "Attaching generated image to Paper #{@paper.id}."
      @paper.image_front.attach(io: StringIO.new(top), filename: "front_#{SecureRandom.hex(4)}.jpg")
      @paper.image_back.attach(theme_input.image_back.blob)
      @paper.save!
      Rails.logger.info "Successfully saved Paper #{@paper.id}"

    # rescue => e
    #   puts "Error during job for Paper #{@paper.id}: #{e.message}"
    #   puts e.backtrace.join("\n")
    #   # Handle error (e.g., update chat status, retry job)
    # ensure
    #   # 7. CRITICAL: Ensure cleanup for both attachments
    #   puts "Ensuring cleanup for Paper #{@paper.id}..."
    # end
  end

  private

  def path_for(attachment)
    ActiveStorage::Blob.service.path_for(attachment.key)
  end
end
