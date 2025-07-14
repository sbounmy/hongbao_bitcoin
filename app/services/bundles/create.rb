module Bundles
  class Create < ApplicationService
    def call(user:, params:)
      @user = user
      @params = params
      @quality = @params.delete(:quality) || ENV.fetch("GPT_IMAGE_QUALITY", "high")
      create_bundle
      create_papers
      create_tokens
    end

    private

    def create_bundle
      @bundle = Bundle.create!(user: @user, **@params)
    end

    def create_papers
      @bundle.styles.each do |style|
        input_items = @bundle.input_items.where(input: [ @bundle.theme, style, @bundle.images.first ])

        paper = Paper.create!(
          name: "#{style.name} #{@bundle.theme.name}",
          prompt: input_items.map(&:prompt).compact_blank.join("\n"),
          input_items:,
          active: true,
          public: false,
          user: @user,
          bundle: @bundle,
        )
        ProcessPaperJob.perform_later(paper.id, quality: @quality)

        Rails.logger.info("Paper created #{paper.id}")
      end
    end

    def create_tokens
      @user.tokens.create(quantity: -@bundle.styles.count, description: "Bundle #{@bundle.id} tokens #{@bundle.styles.map(&:name).join(', ')}")
    end
  end
end
