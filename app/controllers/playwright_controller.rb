class PlaywrightController < ApplicationController
  skip_before_action :verify_authenticity_token

  def force_login
    if params[:email].present?
      user = User.find_by!(email: params.require(:email))
    else
      user = User.first!
    end
    start_new_session_for(user)
    redirect_to URI.parse(params.require(:redirect_to)).path
  end
end
