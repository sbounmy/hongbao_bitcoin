class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_locale
  before_action :set_network
  helper_method :authenticated?, :testnet?, :current_theme, :current_spotify_path, :themes

  private

  def themes
    @themes ||= Input::Theme.with_attached_hero_image
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    {
      locale: I18n.locale,
      testnet: testnet?,
      quality: params[:quality]
    }.compact
  end

  def testnet?
    value = ActiveModel::Type::Boolean.new.cast(params[:testnet])
    value.nil? ? false : value
  end

  def set_network
    Current.network = testnet? ? :testnet : :mainnet
  end


  def current_theme
    @current_theme ||= Input::Theme.find_by(slug: params[:theme] || "usd")
  end

  def current_spotify_path
    current_theme&.spotify_path.presence || "track/40KNlAhOsMqCmfnbRtQrbx"
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { safari: 16, chrome: 110, firefox: 91, opera: 83, ie: false }
end
