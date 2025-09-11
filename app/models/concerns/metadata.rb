module Metadata
  extend ActiveSupport::Concern

  included do
    # Don't use store with JSON columns - Rails handles serialization automatically
    # Just ensure metadata is treated as a hash
    attribute :metadata, :json, default: {}
  end

  # https://www.dsdev.in/store-acc-nested-json
  class_methods do
    def metadata(*fields, accessors: [], prefix: nil, suffix: nil)
      # Build options hash for nested store
      options = {}
      options[:prefix] = prefix unless prefix.nil?
      options[:suffix] = suffix unless suffix.nil?

      store_accessor :metadata, *fields

      fields.each do |field|
        attribute field, :json, default: {}
        store_accessor field, accessors, **options
      end
    end
  end
end
