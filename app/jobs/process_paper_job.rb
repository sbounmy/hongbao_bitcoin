require "stringio"
require "vips"

class ProcessPaperJob < ApplicationJob
  queue_as :default

  def perform(paper_id, quality: "high")
    @paper = Paper.find(paper_id)
    @quality = quality

    input_items = @paper.input_items
    @theme_input = input_items.find { |item| item.input.type == "Input::Theme" }&.input
    @style_input = input_items.find { |item| item.input.type == "Input::Style" }&.input
    @image_input = input_items.find { |item| item.input.type == "Input::Image" }

    Rails.logger.info "[ProcessPaperJob] Processing Paper #{@paper.id}"

    # Step 1: Generate or use portrait
    portrait_blob = generate_portrait

    # Step 2: Attach back image from theme
    @paper.image_back.attach(@theme_input.image_back.blob)

    # Step 3: Composite portrait onto template
    compose_front_image(portrait_blob)
  end

  private

  def generate_portrait
    # No style prompt = use original image as-is (free option)
    if @style_input&.prompt.blank?
      Rails.logger.info "[ProcessPaperJob] No style - using original image"
      @paper.image_portrait.attach(@image_input.image.blob)
      return @image_input.image.download
    end

    # With style prompt = AI transformation
    Rails.logger.info "[ProcessPaperJob] Generating styled portrait"

    base_config = Input::Configuration.instance
    portrait_config = @theme_input.portrait_config
    portrait_resolution = portrait_config["resolution"] || "1024x1024"

    prompts = @paper.input_items.map { |item| item.input.prompt }
    full_prompt = [ base_config.prompt, prompts.flatten ].compact_blank.join(". ")

    Rails.logger.info "[ProcessPaperJob] Using prompt: #{full_prompt}"

    styled_response = Papers::StyleGenerator.call(
      portrait: @image_input.image,
      prompt: full_prompt,
      quality: @quality,
      resolution: portrait_resolution
    )

    @paper.image_portrait.attach(
      io: StringIO.new(styled_response.to_blob),
      filename: "portrait_#{@style_input.slug}_#{SecureRandom.hex(4)}.png"
    )

    # Track AI costs
    @paper.assign_attributes(
      prompt: full_prompt,
      input_tokens: styled_response.usage["input_tokens"],
      output_tokens: styled_response.usage["output_tokens"],
      input_image_tokens: styled_response.usage.dig("input_tokens_details", "image_tokens"),
      input_text_tokens: styled_response.usage.dig("input_tokens_details", "text_tokens"),
      total_tokens: styled_response.usage["total_tokens"],
      total_costs: styled_response.total_cost,
      input_costs: styled_response.input_cost,
      output_costs: styled_response.output_cost
    )

    styled_response.to_blob
  end

  def compose_front_image(portrait_blob)
    Rails.logger.info "[ProcessPaperJob] Compositing onto template"

    composed_image = Papers::Composition.call(
      template: @theme_input.image_front,
      portrait: portrait_blob,
      config: @theme_input.portrait_config
    )

    @paper.image_front.attach(
      io: StringIO.new(composed_image),
      filename: "front_#{SecureRandom.hex(4)}.jpg"
    )

    @paper.save!
    @paper.broadcast_processing_complete
    Rails.logger.info "[ProcessPaperJob] Successfully saved Paper #{@paper.id}"
  end

  def path_for(attachment)
    ActiveStorage::Blob.service.path_for(attachment.key)
  end
end
