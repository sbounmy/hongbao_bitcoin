# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include Rails.application.routes.url_helpers
  include Turbo::StreamsHelper
end
