# frozen_string_literal: true

# This fix rspec assets precompile by skipping turbo broadcasting (we do test then on e2e)
# ActionView::Template::Error: The asset 'tailwind.css' was not found in the load path.
# https://dev.to/edwinthinks/skip-turbo-broadcasting-to-speed-up-seeding-process-in-rails-33cp
class Turbo::StreamsChannel
  [ :broadcast_append_to, :broadcast_prepend_to, :broadcast_replace_to, :broadcast_remove_to ].each do |method|
    define_singleton_method(method) do |*args|
      nil
    end
  end
end
