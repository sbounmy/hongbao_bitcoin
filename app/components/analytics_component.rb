# frozen_string_literal: true

class AnalyticsComponent < ViewComponent::Base
  def initialize(renderable: false)
    @renderable = renderable
  end

  def render?
    Rails.env.production? && @renderable
  end
end
