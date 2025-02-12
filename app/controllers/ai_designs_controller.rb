class AiDesignsController < ApplicationController
  allow_unauthenticated_access only: [ :generate ]

  def index
  end

  def generate
    begin
      # Check if Leonardo API key is configured
      api_key = Rails.application.credentials.dig(:leonardo, :api_key)
      unless api_key.present?
        Rails.logger.error "Leonardo API key is missing"
        return render json: { success: false, error: "API configuration error" }, status: :internal_server_error
      end

      client = LeoAndRuby::Client.new(Rails.application.credentials.dig(:leonardo, :api_key))

      # Get parameters from the request
      prompt = params[:prompt]
      occasion = params[:occasion]
      model_id = "b24e16ff-06e3-43eb-8d33-4416c2d75876"

      unless prompt.present?
        return render json: { success: false, error: "Prompt is required" }, status: :unprocessable_entity
      end
      unless occasion.present?
        return render json: { success: false, error: "Occasion is required" }, status: :unprocessable_entity
      end
      # Combine prompt with occasion if provided
      full_prompt = "A clean bill for #{occasion}"
      Rails.logger.info "Full prompt: #{full_prompt}"
      generation = AiGeneration.create!(
        prompt: full_prompt,
        status: "pending",
        generation_id: SecureRandom.uuid
      )

      theme = Ai::Theme.find_by(title: occasion.titleize)
      user_elements_data = theme.elements.map do |element|
        {
          id: element.element_id.to_i,
          weight: element.weight.to_f
        }
      end

      Rails.logger.info "User elements data: #{user_elements_data}"

      response = client.generate_image_with_user_elements(
        model_id: model_id,
        prompt: full_prompt,
        width: 512,
        height: 512,
        num_images: 1,
        user_elements: user_elements_data
      )
      if response["sdGenerationJob"].present?
        generation.update!(
          generation_id: response["sdGenerationJob"]["generationId"],
          status: "processing"
        )

        render json: {
          success: true,
          generation_id: generation.id,
          generation: generation,
          message: "Generation started"
        }
      else
        Rails.logger.error "Leonardo API error: #{response}"
        render json: { success: false, error: "Invalid API response" }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Leonardo generation error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { success: false, error: "An error occurred while generating the image" },
             status: :internal_server_error
    end
  end

  private

  def webhook_url(generation_id)
    # Make sure APP_URL is set in your environment
    base_url = ENV["APP_URL"] || "https://#{request.host_with_port}"
    "#{base_url}/leonardo_webhook?generation_id=#{generation_id}"
    puts "Webhook URL: #{base_url}/leonardo_webhook?generation_id=#{generation_id}"
  end
end
