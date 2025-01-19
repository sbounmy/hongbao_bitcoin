class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_locale
  before_action :set_network
  helper_method :authenticated?, :testnet?

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    {
      locale: I18n.locale,
      testnet: testnet?
    }.compact
  end

  def testnet?
    value = ActiveModel::Type::Boolean.new.cast(params[:testnet])
    value.nil? ? false : value
  end

  def set_network
    Current.network = testnet? ? :testnet : :mainnet
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { safari: 16, chrome: 110, firefox: 91, opera: 83, ie: false }
end
