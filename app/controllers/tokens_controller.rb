class TokensController < ApplicationController
  def index
    @themes = Ai::Theme.all
    @tokens = current_user.tokens
  end
end
