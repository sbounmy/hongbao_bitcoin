class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  before_action :set_user, only: [ :edit, :update ]
  layout "authentication", only: [ :new, :create ]
  layout 'main', only: [:edit]

  def new
    @user = User.find_or_initialize_by(email: params.dig(:user, :email))
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      render turbo_stream: turbo_stream.action(:redirect, root_path)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def profile_params
    params.require(:user).permit(:firstname, :lastname, :avatar)
  end

  def set_user
    @user = current_user
  end
end
