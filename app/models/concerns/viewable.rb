module Viewable
  extend ActiveSupport::Concern

  included do
    # Ensure the including model has these columns:
    # - views_count: integer
  end

  def increment_views!
    increment!(:views_count)
  end

  def view!
    increment_views!
  end

  def views
    views_count || 0
  end
end