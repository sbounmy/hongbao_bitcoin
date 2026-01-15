class InstagramController < ApplicationController
  def feed
    @instagram_posts = Rails.cache.fetch("instagram_posts", expires_in: 1.hour) do
      InstagramService.new.fetch_media
    end
  end
end