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
      Rails.logger.info("Paper created start  #{@bundle.themes.count} || #{@bundle.styles.count} ----")
      theme = @bundle.input_item_theme.input
      @bundle.styles.each do |style|
        input_items = @bundle.input_items.where(input: [ theme, style, @bundle.images.first ])


        paper = Paper.create!(
          name: "#{style.name} #{theme.name}",
          prompt: input_items.map(&:prompt).compact_blank.join("\n"),
          input_items:,
          active: true,
          public: false,
          user: @user,
          bundle: @bundle,
        )
        ProcessPaperJob.perform_later(paper.id, quality: @quality)

        Rails.logger.info("Paper created #{paper.id} #{paper.name} #{paper.input_items.inspect}")
      end

      Rails.logger.info("Paper created done ----")
    end

    def create_tokens
      @user.tokens.create(quantity: -(@bundle.styles.count * @bundle.themes.count), description: "Bundle #{@bundle.id} tokens #{@bundle.styles.map(&:name).join(', ')} #{@bundle.themes.map(&:name).join(', ')}")
    end
  end
end
