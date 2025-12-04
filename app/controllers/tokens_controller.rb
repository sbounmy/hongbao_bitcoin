class TokensController < ApplicationController
  def index
    @tokens = current_user.tokens
    @product = Product.published.ordered.includes(variants: { images_attachments: :blob }, images_attachments: :blob).last
  end
end
