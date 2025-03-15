class Ai::Images::Create < ApplicationService
  attr_reader :params, :current_user

  def initialize(params:, user:)
    @params = params
    @current_user = user
  end

  def call
    create_image
    generate_image
    success @image
  end

  def create_image
    @image = Ai::Image.create!(
      prompt: full_prompt,
      user: current_user,
      metadata: { theme_id: theme.id }
    )
  end

  def generate_image
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
      @image.update! external_id: response["sdGenerationJob"]["generationId"]
      @image.process!
      @image
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
  end

  def occasion
    params[:occasion]
  end

  def theme
    @theme ||= Ai::Theme.find_by!(title: occasion.titleize)
  end

  def elements
    theme.elements.map do |element|
      {
        id: element.leonardo_id.to_s,
        weight: element.weight.to_f
      }
    end
  end
end
