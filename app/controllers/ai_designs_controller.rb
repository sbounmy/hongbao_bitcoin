class AiDesignsController < ApplicationController
  require 'httparty'
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

      # Get parameters from the request
      prompt = params[:prompt]
      occasion = params[:occasion]
      model_id = "b24e16ff-06e3-43eb-8d33-4416c2d75876"

      # Log the incoming parameters
      Rails.logger.info "Generating image with prompt: #{prompt}, occasion: #{occasion}"

      # Validate required parameters
      unless prompt.present?
        return render json: { success: false, error: "Prompt is required" }, status: :unprocessable_entity
      end

      # Combine prompt with occasion if provided
      full_prompt = "A beautiful, modern, elegant and #{prompt} bank note for a #{occasion}."
      Rails.logger.info "Full prompt: #{full_prompt}"

      # Create an AiGeneration record to track the request
      generation = AiGeneration.create!(
        prompt: full_prompt,
        status: "pending",
        generation_id: SecureRandom.uuid
      )

      # Make direct API call to Leonardo
      url = "https://cloud.leonardo.ai/api/rest/v1/generations"
      headers = {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }

      body = {
        prompt: full_prompt,
        modelId: model_id,
        width: 512,
        height: 512,
        num_images: 1,
        negative_prompt: "has background",
        userElements: [
          {
            userLoraId: 26060,  # BIRTHDAY THEME BILLS element
            weight: 0.7
          }
        ]
      }

      response = HTTParty.post(
        url,
        headers: headers,
        body: body.to_json
      )

      if response.success? && response.parsed_response["sdGenerationJob"].present?
        generation_data = response.parsed_response["sdGenerationJob"]
        generation.update!(
          generation_id: generation_data["generationId"],
          status: "processing"
        )

        render json: {
          success: true,
          generation_id: generation.id,
          generation: generation,
          message: "Generation started"
        }
      else
        Rails.logger.error "Leonardo API error: #{response.body}"
        render json: { success: false, error: "Invalid API response" }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Leonardo generation error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { success: false, error: "An error occurred while generating the image" },
             status: :internal_server_error
    end
  end

  def get_user_info
    begin
      url = "https://cloud.leonardo.ai/api/rest/v1/me"
      headers = {
        "Authorization" => "Bearer #{Rails.application.credentials.dig(:leonardo, :api_key)}",
        "Content-Type" => "application/json"
      }

      response = HTTParty.get(
        url,
        headers: headers
      )

      if response.success?
        render json: {
          success: true,
          user_info: response.parsed_response
        }
      else
        Rails.logger.error "Leonardo API error: #{response.body}"
        render json: {
          success: false,
          error: "Failed to fetch user information"
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Leonardo user info error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        success: false,
        error: "An error occurred while fetching user information"
      }, status: :internal_server_error
    end
  end

  def get_custom_elements
    begin
      # Get user info using existing method
      user_response = get_user_info_data

      unless user_response[:success]
        return render json: user_response, status: :unprocessable_entity
      end

      user_id = user_response[:user_info]["user_details"][0]["user"]["id"]

      # Get the custom elements using the user ID
      elements_url = "https://cloud.leonardo.ai/api/rest/v1/elements/user/#{user_id}"
      headers = {
        "Authorization" => "Bearer #{Rails.application.credentials.dig(:leonardo, :api_key)}",
        "Content-Type" => "application/json"
      }

      elements_response = HTTParty.get(
        elements_url,
        headers: headers
      )

      if elements_response.success?
        render json: {
          success: true,
          elements: elements_response.parsed_response
        }
      else
        Rails.logger.error "Leonardo API error: #{elements_response.body}"
        render json: {
          success: false,
          error: "Failed to fetch custom elements"
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Leonardo custom elements error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        success: false,
        error: "An error occurred while fetching custom elements"
      }, status: :internal_server_error
    end
  end

  private

  def webhook_url(generation_id)
    base_url = ENV["APP_URL"] || "https://#{request.host_with_port}"
    "#{base_url}/leonardo_webhook?generation_id=#{generation_id}"
  end

  def get_user_info_data
    url = "https://cloud.leonardo.ai/api/rest/v1/me"
    headers = {
      "Authorization" => "Bearer #{Rails.application.credentials.dig(:leonardo, :api_key)}",
      "Content-Type" => "application/json"
    }

    response = HTTParty.get(
      url,
      headers: headers
    )

    if response.success?
      {
        success: true,
        user_info: response.parsed_response
      }
    else
      Rails.logger.error "Leonardo API error: #{response.body}"
      {
        success: false,
        error: "Failed to fetch user information"
      }
    end
  rescue StandardError => e
    Rails.logger.error "Leonardo user info error: #{e.message}\n#{e.backtrace.join("\n")}"
    {
      success: false,
      error: "An error occurred while fetching user information"
    }
  end
end
