# frozen_string_literal: true

class InfiniteScrollComponent < ApplicationComponent
  attr_reader :collection, :pagy, :path_method, :container_id, :container_classes,
              :loader_text, :turbo_stream_action, :grid_classes

  def initialize(collection:, pagy:, path_method:, container_id:, **options)
    @collection = collection
    @pagy = pagy
    @path_method = path_method
    @container_id = container_id

    # Options with sensible defaults
    @container_classes = options.fetch(:container_classes, "")
    @grid_classes = options.fetch(:grid_classes, "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4")
    @loader_text = options.fetch(:loader_text, "Loading more...")
    @turbo_stream_action = options.fetch(:turbo_stream_action, :append)
  end

  def render?
    collection.present?
  end

  private

  def loader_id
    "#{container_id}_page_#{pagy.next}"
  end

  def next_page_path
    path_method.call(page: pagy.next, format: :turbo_stream)
  end
end
