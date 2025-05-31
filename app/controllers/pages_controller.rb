class PagesController < ApplicationController
  allow_unauthenticated_access
  def index
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
  end

  def satoshi
  end

  def about
  end

  def v2
    # Will be used to list available styles and papers
    @styles = Input::Style.with_attached_image
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
    @instagram_posts = cache("instagram_posts", expires_in: 2.hour) { InstagramService.new.fetch_media }
  end

  def wedding
    @papers = Paper.active.recent.with_attached_image_front.with_attached_image_back
  end

end
