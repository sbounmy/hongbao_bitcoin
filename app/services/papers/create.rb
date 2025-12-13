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
      # Create the paper - name will be set automatically by before_save callback
      # InputItem handles blob_id via before_validation callback
      @paper = Paper.create!(user: @user, active: true, public: false, **@params)
      ProcessPaperJob.perform_later(@paper.id, quality: @quality)
    end

    def create_tokens
      return if @paper.style&.prompt.blank?
      @user.tokens.create(quantity: -1, description: "Paper #{@paper.id} tokens #{@paper.style.name}")
    end
  end
end
