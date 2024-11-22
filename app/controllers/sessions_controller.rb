class SessionsController < ApplicationController
  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out successfully"
  end
end
