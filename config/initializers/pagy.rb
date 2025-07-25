# frozen_string_literal: true

# Pagy initializer file (9.3.5)
# Customize only what you really need and notice that the core Pagy works also without any of the following lines.

# Pagy Variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#variables
# All the Pagy::DEFAULT are set for all the Pagy instances but can be overridden per instance by just passing them to
# Pagy.new|Pagy::Countless.new|Pagy::Calendar::*.new or any of the #pagy* controller methods

# Instance variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#instance-variables
Pagy::DEFAULT[:limit] = 20                                  # default

# Other Variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#other-variables
# Pagy::DEFAULT[:size] = 7                                  # default
# Pagy::DEFAULT[:ends] = true                               # default
# Pagy::DEFAULT[:page_param] = :page                        # default
# Pagy::DEFAULT[:count_args] = []                           # default
# Pagy::DEFAULT[:max_pages] = nil                           # default

# Extras
# See https://ddnexus.github.io/pagy/categories/extra

# Backend Extras

# Countless extra: Paginate without the need of any count, saving one query per rendering
# See https://ddnexus.github.io/pagy/docs/extras/countless
require 'pagy/extras/countless'
# Pagy::DEFAULT[:countless_minimal] = false                 # default (eager loading)

# Headers extra: http response headers with pagination info (and other helpers)
# See https://ddnexus.github.io/pagy/docs/extras/headers
# require 'pagy/extras/headers'
# Pagy::DEFAULT[:headers] = { page: 'current-page',
#                             limit: 'page-items',
#                             count: 'total-count',
#                             pages: 'total-pages' }      # default

# Overflow extra: Allow for easy handling of overflowing pages
# See https://ddnexus.github.io/pagy/docs/extras/overflow
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page                       # (other options: :empty_page and :exception)

# Rails
# Enable the helpful rails support by including the rails extra
# See https://ddnexus.github.io/pagy/docs/extras/rails
# require 'pagy/extras/rails'