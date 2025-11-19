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
    style_input = input_items.find { |item| item.input.type == "Input::Style" }&.input
    image_input = input_items.find { |item| item.input.type == "Input::Image" }

    prompts = input_items.map { |item| item.input.prompt }

    Rails.logger.info "[ProcessPaperJob] Processing Paper #{@paper.id}"

    # Get base configuration for AI framing prompt (creates if doesn't exist)
    base_config = Input::Configuration.instance

    # Step 1: AI transforms portrait into style with base framing prompt
    Rails.logger.info "[ProcessPaperJob] Step 1: Generating styled portrait"
    portrait_config = theme_input.portrait_config
    portrait_resolution = portrait_config["resolution"] || "1024x1024"

    # Combine base framing prompt with style prompt
    full_prompt = [base_config.prompt, prompts.flatten].compact_blank.join(". ")

    Rails.logger.info "[ProcessPaperJob] Using prompt: #{full_prompt}"

    styled_portrait_response = Papers::StyleGenerator.call(
      portrait: image_input.image, # Use original image directly
      prompt: full_prompt,
      quality: quality,
      resolution: portrait_resolution
    )
    @paper.image_portrait.attach(
      io: StringIO.new(styled_portrait_response.to_blob),
      filename: "portrait_#{style_input.slug}_#{SecureRandom.hex(4)}.png"
    )


    # Track AI costs
    @paper.assign_attributes(
      prompt: full_prompt,
      input_tokens: styled_portrait_response.usage["input_tokens"],
      output_tokens: styled_portrait_response.usage["output_tokens"],
      input_image_tokens: styled_portrait_response.usage.dig("input_tokens_details", "image_tokens"),
      input_text_tokens: styled_portrait_response.usage.dig("input_tokens_details", "text_tokens"),
      total_tokens: styled_portrait_response.usage["total_tokens"],
      total_costs: styled_portrait_response.total_cost,
      input_costs: styled_portrait_response.input_cost,
      output_costs: styled_portrait_response.output_cost
    )

    # Attach theme's back image
    @paper.image_back.attach(theme_input.image_back.blob)
    @paper.save!
    Rails.logger.info "[ProcessPaperJob] Successfully saved Paper #{@paper.id}"

    # Step 2: Composite styled portrait onto template
    Rails.logger.info "[ProcessPaperJob] Step 2: Compositing onto template"
    composed_image = Papers::Composition.call(
      template: theme_input.image_front,
      portrait: styled_portrait_response.to_blob,
      config: theme_input.portrait_config
    )
    # Attach composed front image
    @paper.image_front.attach(
      io: StringIO.new(composed_image),
      filename: "front_#{SecureRandom.hex(4)}.jpg"
    )

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
