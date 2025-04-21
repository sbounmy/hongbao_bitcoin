class InstagramController < ApplicationController
  def feed
    @instagram_posts = InstagramPost.active.ordered
  end
end
