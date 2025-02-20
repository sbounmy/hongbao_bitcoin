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
      model_id = "2067ae52-33fd-4a82-bb92-c2c55e7d2786"

      unless occasion.present?
        return render json: { success: false, error: "Occasion is required" }, status: :unprocessable_entity
      end

      full_prompt = "Blue"
      Rails.logger.info "Full prompt: #{full_prompt}"
      generation = Ai::Generation.create!(
        prompt: full_prompt,
        status: "pending",
        generation_id: SecureRandom.uuid,
        user: current_user
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

        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.update("ai_designs_results",
                partial: "hong_baos/new/steps/design/generated_designs",
                locals: { papers_by_user: current_user.papers }
              )
            ]
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
