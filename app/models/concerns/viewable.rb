module Viewable
  extend ActiveSupport::Concern

  included do
    # Ensure the including model has these columns:
    # - views_count: integer
  end

  def increment_views!(session)
    return if already_viewed?(session)

    mark_as_viewed!(session)
    increment!(:views_count)
  end

  def views
    views_count || 0
  end

  private

  def viewed_session_key
    "viewed_#{self.class.name.underscore}_ids"
  end

  def already_viewed?(session)
    (session[viewed_session_key] || []).include?(id)
  end

  def mark_as_viewed!(session)
    session[viewed_session_key] ||= []
    session[viewed_session_key] << id
  end
end
