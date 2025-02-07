class AiGenerationsController < ApplicationController
  before_action :set_ai_generation, only: [ :show, :edit, :update, :destroy ]
  # after_action :broadcast_ai_generations, only: [ :update ]

  def index
    @ai_generations = AiGeneration.all
  end

  def show
  end

  def new
    @ai_generation = AiGeneration.new
  end

  def create
    @ai_generation = AiGeneration.new(ai_generation_params)

    if @ai_generation.save
      redirect_to @ai_generation, notice: "AI generation was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @ai_generation.update(ai_generation_params)
      redirect_to @ai_generation, notice: "AI generation was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @ai_generation.destroy
    redirect_to ai_generations_url, notice: "AI generation was successfully deleted."
  end

  private

  def set_ai_generation
    @ai_generation = AiGeneration.find(params[:id])
  end

  def ai_generation_params
    params.require(:ai_generation).permit(:prompt, :generation_id, :status, image_urls: [])
  end
end
