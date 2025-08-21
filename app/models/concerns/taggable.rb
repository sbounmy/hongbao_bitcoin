# frozen_string_literal: true

module Taggable
  extend ActiveSupport::Concern

  included do
    array_columns :tag_ids

    scope :with_tag_name, ->(name) { with_any_tag_ids(Tag.find_by(name:)&.id) }
  end

  def tags
    @tags ||= Tag.where(id: tag_ids)
  end

  def tag_names
    tags.pluck(:name)
  end
end
