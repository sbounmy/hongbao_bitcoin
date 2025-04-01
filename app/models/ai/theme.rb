module Ai
  class Theme < ApplicationRecord
    has_and_belongs_to_many :elements
    has_one_attached :hero_image
    validates :title, presence: true
    # validates :elements, presence: true
    validates :path, presence: true, uniqueness: true

    store :settings, accessors: [
      :primary_color,
      :secondary_color,
      :accent_color,
      :background_color,
      :text_color
    ], prefix: true

    before_validation :set_default_path, on: :create
    before_validation :set_default_colors, on: :create

    def self.ransackable_attributes(auth_object = nil)
      [ "created_at", "id", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "elements" ]
    end

    private

    def set_default_path
      self.path ||= title.parameterize
    end

    def set_default_colors
      self.settings_primary_color ||= "#F04747"
      self.settings_secondary_color ||= "#FFB636"
      self.settings_accent_color ||= "#FFD699"
      self.settings_background_color ||= "#FFFFFF"
      self.settings_text_color ||= "#000000"
    end
  end
end
