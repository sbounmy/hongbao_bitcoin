module Papers
  class Create < ApplicationService
    def call(user:, params:)
      @user = user
      @params = params
      @quality = @params.delete(:quality) || ENV.fetch("GPT_IMAGE_QUALITY", "high")
      create_paper
      create_tokens if @user
      @paper
    end

    private

    def create_paper
      # Add default values for required fields
      paper_params = @params.merge(
        name: "Paper #{SecureRandom.hex(4)}",
      )

      @paper = Paper.create!(user: @user, active: true, public: false, **paper_params)
      ProcessPaperJob.perform_later(@paper.id, quality: @quality)
    end

    def create_tokens
      @user.tokens.create(quantity: -1, description: "Paper #{@paper.id} tokens #{@paper.style.name}")
    end
  end
end