module Ai
  class Theme < ApplicationRecord
    # List of all possible theme properties
    CSS_PROPERTIES = [
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
    UI_PROPERTIES = CSS_PROPERTIES.map(&:underscore)

    has_and_belongs_to_many :elements
    has_one_attached :hero_image
    validates :title, presence: true
    validates :ui_name, presence: true
    # validates :elements, presence: true
    validates :path, presence: true, uniqueness: true

    store :ui, accessors: [ :name ] + UI_PROPERTIES, prefix: true

    before_validation :set_defaults, on: :create

    def self.ransackable_attributes(auth_object = nil)
      [ "created_at", "id", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "elements" ]
    end

    def theme_property(property)
      ui[property.to_s].presence
    end

    def theme_properties
      UI_PROPERTIES
    end

    private

    def set_defaults
      self.ui_name ||= "sunset"
      self.path ||= (title || "").parameterize
    end
  end
end
