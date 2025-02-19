module Ai
  class Theme < ApplicationRecord
    has_and_belongs_to_many :elements

    validates :title, presence: true
    validates :elements, presence: true

    def self.ransackable_attributes(auth_object = nil)
      [ "created_at", "id", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "elements" ]
    end
  end
end
