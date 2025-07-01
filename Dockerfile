# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t hongbao .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name hongbao hongbao

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.8
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages needed for both build and runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Build args for git info
ARG COMMIT_SHA
ARG COMMIT_TIME

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    COMMIT_SHA="${COMMIT_SHA}" \
    COMMIT_TIME="${COMMIT_TIME}"

# --- Build Stage ---
FROM base AS build

# Install packages needed ONLY to build gems and JS
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# --- Gem Installation ---
# First, copy only the files needed for bundle install
COPY Gemfile Gemfile.lock ./
# This layer is only invalidated when Gemfile.lock changes
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# --- Yarn Installation ---
# Next, copy only the files needed for yarn install
COPY package.json yarn.lock ./
# This layer is only invalidated when yarn.lock changes
RUN yarn install

# --- Application Code ---
# Finally, copy the rest of the application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# --- Final App Image ---
FROM base

# Copy installed gems and application code from the build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails data db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]