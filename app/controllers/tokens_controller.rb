class TokensController < ApplicationController
  def index
    @tokens = current_user.tokens
  end
end
