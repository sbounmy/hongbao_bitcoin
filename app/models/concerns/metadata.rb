module Metadata
  extend ActiveSupport::Concern

  included do
    store :metadata, coder: JSON
  end

  class_methods do
    def metadata(*fields, accessors: nil, prefix: nil, suffix: nil)
      if fields.length == 1 && accessors
        # Nested hash with multiple accessors
        field = fields.first
        store :metadata, accessors: [ field ]

        # Build options hash for nested store
        options = {}
        options[:accessors] = accessors
        options[:prefix] = prefix unless prefix.nil?
        options[:suffix] = suffix unless suffix.nil?

        store field, coder: JSON, **options
      else
        # Simple accessors for one or more fields
        store_accessor :metadata, *fields
      end
    end
  end
end
