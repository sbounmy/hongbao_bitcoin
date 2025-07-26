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

  def loader_frame(loading: true)
    return "" unless pagy.next

    turbo_frame_tag loader_id,
                    src: loading ? next_page_path : nil,
                    loading: loading ? :lazy : nil do
      loader_content
    end
  end

  private

  def loader_id
    "#{container_id}_page_#{pagy.next}"
  end

  def next_page_path
    path_method.call(page: pagy.next, format: :turbo_stream)
  end

  def loader_content
    tag.div(class: "col-span-full flex justify-center items-center py-8") do
      tag.div(class: "flex flex-col items-center gap-2") do
        safe_join([
          tag.span(class: "loading loading-spinner loading-lg text-primary"),
          tag.span(loader_text, class: "text-base-content/60")
        ])
      end
    end
  end
end
