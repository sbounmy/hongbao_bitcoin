class ApplicationController < ActionController::Base
  # include Authentication
  before_action :set_locale
  helper_method :authenticated?

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { safari: 16, chrome: 110, firefox: 91, opera: 83, ie: false }
end
