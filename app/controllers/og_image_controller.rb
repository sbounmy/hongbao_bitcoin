class OgImageController < ApplicationController
  allow_unauthenticated_access
  # Skip any authentication if you have it

  # Skip CSRF protection as this is just for viewing
  skip_before_action :verify_authenticity_token

  # layout false # Don't use the application layout

  def show
    # Set response headers for better caching
    response.headers["Cache-Control"] = "public, max-age=31536000"
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    @width, @height = params[:size].split("x")
    @width = @width.to_i || 1200
    @height = @height.to_i || 630
  end
end
