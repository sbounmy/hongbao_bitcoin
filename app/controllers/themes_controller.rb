class ThemesController < ApplicationController
  allow_unauthenticated_access only: [ :new, :index ]
  layout "main"

  def new
    # Render the theme submission form
  end

  def index
    @themes = Input::Theme.active.by_position.with_attached_image_hero.with_attached_image_front.with_attached_image_back
    @current_id = params[:current_id].to_i
    render layout: false
  end
end
