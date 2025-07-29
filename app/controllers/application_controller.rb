class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend
  before_action :set_locale
  helper_method :authenticated?, :current_theme, :current_spotify_path, :themes

  private

  def themes
    @themes ||= Input::Theme.with_attached_image_hero
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end


  def current_theme
    @current_theme ||= Input::Theme.find_by!(slug: params[:theme] || "usd")
  end

  def current_spotify_path
    current_theme&.spotify_path.presence || "track/40KNlAhOsMqCmfnbRtQrbx"
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { safari: 16, chrome: 110, firefox: 91, opera: 83, ie: false }
end
