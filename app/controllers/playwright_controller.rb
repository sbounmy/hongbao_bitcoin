class PlaywrightController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :force_login ]
  allow_unauthenticated_access only: [ :force_login ]

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
