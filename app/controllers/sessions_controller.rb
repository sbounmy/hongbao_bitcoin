class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }
  layout "authentication", only: [ :new ]
  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email, :password))
      start_new_session_for user
      render turbo_stream: turbo_stream.action(:redirect, after_authentication_url)
    else
      redirect_to signup_path(user: { email: params[:email] }), alert: "Password is incorrect"
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out successfully"
  end
end
