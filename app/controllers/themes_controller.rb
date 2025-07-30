class ThemesController < ApplicationController
  allow_unauthenticated_access only: [ :new ]
  layout "main"

  def new
    # Render the theme submission form
  end
end
