class AiDesignsController < ApplicationController
  def index
  end

  def create
    begin
      # Check if Leonardo API key is configured
      api_key = Rails.application.credentials.dig(:leonardo, :api_key)
      unless api_key.present?
        Rails.logger.error "Leonardo API key is missing"
        return render json: { success: false, error: "API configuration error" }, status: :internal_server_error
      end

      client = LeoAndRuby::Client.new(Rails.application.credentials.dig(:leonardo, :api_key))

      # Get parameters from the request
      occasion = params[:occasion]
      face_to_swap = params[:image]
      model_id = "2067ae52-33fd-4a82-bb92-c2c55e7d2786"

      unless occasion.present?
        return render json: { success: false, error: "Occasion is required" }, status: :unprocessable_entity
      end

      full_prompt = "A #{occasion} bitcoin themed bill add text public address and private key"
      Rails.logger.info "Full prompt: #{full_prompt}"
      generation = Ai::Generation.create!(
        prompt: full_prompt,
        status: "pending",
        generation_id: SecureRandom.uuid,
        user: current_user,
        face_to_swap: face_to_swap
      )

      # Get theme elements
      theme = Ai::Theme.find_by(title: occasion.titleize)
      user_elements_data = theme.elements.map do |element|
        {
          id: element.leonardo_id.to_i,
          weight: element.weight.to_f
        }
      end

      Rails.logger.info "User elements data: #{user_elements_data}"

      # Generate image
      begin
        response = client.generate_image_with_user_elements(
          model_id: model_id,
          prompt: full_prompt,
          width: 512,
          height: 512,
          presetStyle: "ILLUSTRATION",
          num_images: 1,
          promptMagic: false,
          enhancePrompt: false,
          user_elements: user_elements_data
        )
      rescue SocketError => e
        Rails.logger.error "Network connection error: #{e.message}"
        return render json: { error: "Unable to connect to AI service. Please try again later." }, status: :service_unavailable
      rescue => e
        Rails.logger.error "Leonardo API error: #{e.message}"
        return render json: { error: "AI service error. Please try again later." }, status: :service_unavailable
      end

      if response["sdGenerationJob"].present?
        generation.update!(
          generation_id: response["sdGenerationJob"]["generationId"],
          status: "processing"
        )

        respond_to do |format|
          format.turbo_stream {
            Rails.logger.debug "Papers for user: #{current_user.papers.inspect}"
            render turbo_stream: []
          }
        end
      else
        render json: { error: "Generation failed" }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Generation error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def webhook_url(generation_id)
    base_url = ENV["APP_URL"] || "https://#{request.host_with_port}"
    "#{base_url}/leonardo_webhook?generation_id=#{generation_id}"
  end
end
