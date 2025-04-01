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
      super || "dark"
    end

    private

    def set_default_path
      self.path ||= title.parameterize
    end
  end
end
