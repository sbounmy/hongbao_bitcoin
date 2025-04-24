class PagesController < ApplicationController
  allow_unauthenticated_access
  def index
    # Will be used to list available styles and papers
    @styles = Input::Style.all
    @papers = Paper.all
    @themes = Ai::Theme.all
    @bundle = Bundle.new
    @bundle.input_items.build(input: Input::Theme.first)
    @instagram_posts = cache("instagram_posts", expires_in: 2.hour) { InstagramService.new.fetch_media }
  end
end
