module Ai
  class Theme < ApplicationRecord
    has_and_belongs_to_many :elements
    has_one_attached :hero_image
    validates :title, presence: true
    # validates :elements, presence: true
    validates :path, presence: true, uniqueness: true

    store :ui, accessors: [ :name ], prefix: true

    before_validation :set_default_path, on: :create
    before_validation :set_default_theme, on: :create

    def self.ransackable_attributes(auth_object = nil)
      [ "created_at", "id", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "elements" ]
    end

    def ui_name
      super || "sunset"
    end

    def set_default_theme
      self.ui_name ||= "sunset"
    end

    def theme_property(property)
      ui[property.to_s].presence
    end

    def theme_properties
      THEME_PROPERTIES
    end

    # List of all possible theme properties
    THEME_PROPERTIES = [
      "color-base-100", "color-base-200", "color-base-300", "color-base-content",
      "color-primary", "color-primary-content",
      "color-secondary", "color-secondary-content",
      "color-accent", "color-accent-content",
      "color-neutral", "color-neutral-content",
      "color-info", "color-info-content",
      "color-success", "color-success-content",
      "color-warning", "color-warning-content",
      "color-error", "color-error-content",
      "radius-selector", "radius-field", "radius-box",
      "size-selector", "size-field",
      "border",
      "depth",
      "noise"
    ]

    private

    def set_default_path
      self.path ||= title.parameterize
    end
  end
end
