class TokensController < ApplicationController
  def index
    @themes = Input::Theme.all
    @tokens = current_user.tokens
  end
end
