class PagesController < ApplicationController
  allow_unauthenticated_access
  def index
    @users = User.joins(:avatar_attachment).with_attached_avatar.limit(8)
    @saved_hong_baos = User.find_by(email: "stephane@hackerhouse.paris")&.saved_hong_baos || SavedHongBao.none
  end

  def pricing
  end

  def v2
    # Will be used to list available styles and papers
    @styles = Input::Style.by_position.with_attached_image
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back.limit(5)
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
    @instagram_posts = cache("instagram_posts", expires_in: 2.hour) { InstagramService.new.fetch_media }
  end
end
