# app/components/content_loader_component.rb
# frozen_string_literal: true

class ContentLoaderComponent < ApplicationComponent
  attr_reader :options
  # @param url [String] The URL to fetch content from. (Required)
  # @param refresh_interval [Integer, nil] Interval in milliseconds to reload content. (Optional)
  # @param lazy_loading [Boolean] Fetch content when element is visible. (Optional, default: false)
  # @param lazy_loading_root_margin [String, nil] rootMargin option for Intersection Observer (e.g., "100px"). (Optional)
  # @param lazy_loading_threshold [Float, Integer, nil] threshold option for Intersection Observer (e.g., 0.5). (Optional)
  # @param load_scripts [Boolean] Load inline scripts from the fetched content. (Optional, default: false)
  def initialize(options = {})
    super
    @options = options
    @options.transform_keys! { |key| "content_loader_#{key}_value" }
  end
end
