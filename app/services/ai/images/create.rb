class Ai::Images::Create < ApplicationService
  def call(params)
    create_image(params)
    generate_image(params)
  end

  def create_image(params)
    @image = Ai::Image.create!(
      prompt: full_prompt,
      status: "pending",
      user: current_user
    )
  end

  def generate_image(params)
    client.generate_image_with_user_elements(
      model_id: model_id,
      prompt: full_prompt,
      width: 512,
      height: 512,
      presetStyle: "ILLUSTRATION",
      num_images: 1,
      promptMagic: false,
      enhancePrompt: false,
      user_elements: elements
    ).tap do |response|
      @image.update!(
        external_id: response["sdGenerationJob"]["generationId"],
        status: "processing"
      )
    end
  end

  def client
    @client ||= LeoAndRuby::Client.new(credentials(:leonardo, :api_key))
  end

  def full_prompt
    "A #{occasion} bitcoin themed bill add text public address and private key"
  end

  def model_id
    "2067ae52-33fd-4a82-bb92-c2c55e7d2786"
  end # Get parameters from the request

  def theme
    @theme ||= Ai::Theme.find_by(title: params[:occasion].titleize)
  end

  def elements
    theme.elements.map do |element|
      {
        id: element.leonardo_id.to_i,
        weight: element.weight.to_f
      }
    end
  end
end
