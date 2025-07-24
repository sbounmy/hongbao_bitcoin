class PasswordComponent < ApplicationComponent
  def initialize(action: :new, user: nil, token: nil)
    @action = action
    @user = user
    @token = token
  end

  private

  attr_reader :action, :user, :token
end
