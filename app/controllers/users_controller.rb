class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.find_or_initialize_by(email: params.dig(:user, :email))
    @themes = Input::Theme.all
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      render turbo_stream: turbo_stream.action(:redirect, root_path)
    else
      @themes = Input::Theme.all
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
