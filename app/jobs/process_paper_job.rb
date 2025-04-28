require "stringio"
require "vips"
# Assuming Faraday is required elsewhere or autoloaded

class ProcessPaperJob < ApplicationJob
  queue_as :default

  def perform(chat)
    @chat = chat
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

      puts "Calling RubyLLM.edit for Chat #{@chat.id} with prompt, theme, and image."
      # 5. Call the LLM service
      response = RubyLLM.edit(
        prompt,
        model: "gpt-image-1",
        # Pass both prepared FileParts as required
        # Adjust keys (`image:`, `theme:`) as needed by RubyLLM.edit
        with: { image: [ ActiveStorage::Blob.service.path_for(theme_attachment.key), ActiveStorage::Blob.service.path_for(image_attachment.key) ] }
      )

      # 6. Process the response
      paper = Paper.new(
        name: "Generated Paper #{SecureRandom.hex(4)}",
        active: true,
        public: false,
        user: chat.user,
        # chat: @chat
      )

      top, bottom = split_image(response.to_blob)

      puts "Attaching generated image to Paper for Chat #{@chat.id}."
      paper.image_front.attach(io: top, filename: "front_#{SecureRandom.hex(4)}.jpg")
      paper.image_back.attach(io: bottom, filename: "back_#{SecureRandom.hex(4)}.jpg")
      paper.save!
      puts "Successfully saved Paper #{paper.id} for Chat #{@chat.id}."
      puts "Paper: #{ActiveStorage::Blob.service.path_for(paper.image_front.key).inspect}"
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

  def prompt
    puts "input items: #{@chat.input_items.pluck(:input_id)}"
    puts "Prompt: #{@chat.input_items.map(&:prompt)}"
    @chat.input_items.map(&:prompt).compact.join("\n")
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
end
