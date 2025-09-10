module Metadata
  extend ActiveSupport::Concern

  included do
    # Don't use store with JSON columns - Rails handles serialization automatically
    # Just ensure metadata is treated as a hash
    attribute :metadata, :json, default: {}
  end

  class_methods do
    def metadata(*fields, accessors: nil, prefix: nil, suffix: nil)
      if fields.length == 1 && accessors
        # Nested hash with multiple accessors
        field = fields.first
        store_accessor :metadata, field

        # Build options hash for nested store
        options = {}
        options[:accessors] = accessors
        options[:prefix] = prefix unless prefix.nil?
        options[:suffix] = suffix unless suffix.nil?

        store field, **options
      else
        # Simple accessors for one or more fields
        store_accessor :metadata, *fields
      end
    end
  end
end
