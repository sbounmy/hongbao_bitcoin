# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

USER vscode
# Remove the .devcontainer/ prefix since the context is already in that directory
COPY .aliases /home/vscode/.bash_aliases
