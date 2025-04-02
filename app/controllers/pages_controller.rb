class PagesController < ApplicationController
  allow_unauthenticated_access
  def index
    # Will be used to list available styles and papers
    @styles = Ai::Style.all
    @papers = Paper.all
  end
end
