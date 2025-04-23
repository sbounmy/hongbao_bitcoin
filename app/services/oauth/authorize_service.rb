# frozen_string_literal: true

module Oauth
  class AuthorizeService < ApplicationService
    # No specific initialization needed for this service

    def call
      google_url = client.auth_code.authorize_url(
        redirect_uri: callback_oauth_url, # URL helpers included from ApplicationService
        scope: "openid email profile",
        access_type: "online"
      )
      Rails.logger.info("Generated Google OAuth URL: #{google_url}")
      success(google_url) # Return success Response object with the URL
    rescue OAuth2::Error => e
      # failure() helper from ApplicationService handles logging/re-raising
      failure(e)
    end

    private

    def client
      OAuth2::Client.new(
        credentials(:google, :client_id), # credentials helper from ApplicationService
        credentials(:google, :client_secret),
        site: "https://accounts.google.com",
        authorize_url: "/o/oauth2/auth"
      )
    end
  end
end
