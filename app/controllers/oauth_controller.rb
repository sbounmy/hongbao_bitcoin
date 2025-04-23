# frozen_string_literal: true

class OauthController < ApplicationController
  allow_unauthenticated_access only: [ :authorize, :callback ]

  def authorize
    result = Oauth::AuthorizeService.call

    if result.success?
      render turbo_stream: turbo_stream.action(:redirect, result.payload)
    else
      alert_message = result.error&.message || "Could not initiate Google sign-in."
      redirect_to signup_path, alert: "#{alert_message} Please try again later."
    end
  end

  def callback
    result = Oauth::CallbackService.call(params[:code])

    if result.success?
      user = result.payload
      start_new_session_for(user) # Assumes this helper exists
      redirect_to root_path, notice: "Successfully signed in with Google."
    else
      error = result.error
      alert_message = if error.is_a?(Oauth::CallbackService::CallbackError) && error.user_message.present?
                        error.user_message
      else
                        # Fallback for generic errors or if no user_message was set
                        error&.message || "An unknown error occurred during Google sign-in."
      end
      redirect_to signup_path, alert: alert_message
    end
  end
end
