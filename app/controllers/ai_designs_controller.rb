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
      model_id = "2067ae52-33fd-4a82-bb92-c2c55e7d2786"

      unless occasion.present?
        return render json: { success: false, error: "Occasion is required" }, status: :unprocessable_entity
      end
      # Combine prompt with occasion if provided
      full_prompt = "A #{occasion} bill with public address and private key"
      Rails.logger.info "Full prompt: #{full_prompt}"
      generation = AiGeneration.create!(
        prompt: full_prompt,
        status: "pending",
        generation_id: SecureRandom.uuid
      )

      # Get theme elements
      theme = Ai::Theme.find_by(title: occasion.titleize)
      user_elements_data = theme.elements.map do |element|
        {
          id: element.element_id.to_i,
          weight: element.weight.to_f
        }
      end

      Rails.logger.info "User elements data: #{user_elements_data}"

      # Generate image
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
    base_url = ENV["APP_URL"] || "https://#{request.host_with_port}"
    "#{base_url}/leonardo_webhook?generation_id=#{generation_id}"
  end
end
