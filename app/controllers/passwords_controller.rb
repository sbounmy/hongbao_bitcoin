class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  layout "main"

  def new
  end

  def create
    if user = User.find_by(email: params[:email])
      PasswordsMailer.reset(user).deliver_later
      redirect_to login_path, notice: "Password reset instructions sent to #{params[:email]}"
    else
      redirect_to new_password_path, alert: "No account found with email #{params[:email]}"
    end
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to login_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
