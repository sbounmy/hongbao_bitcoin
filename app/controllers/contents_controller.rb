class ContentsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_content_class

  def index
    @contents = @content_class.published
                               .order(published_at: :desc)
                               .page(params[:page])
    render "contents/#{@content_type}/index"
  end

  def show
    @content = @content_class.published.friendly.find(params[:slug])

    # Redirect to the current slug if accessing via an old slug for SEO
    if params[:slug] != @content.slug
      redirect_to bitcoin_content_path(@content, klass: params[:klass]), status: :moved_permanently
      return
    end

    @content.increment!(:impressions_count)
    @related = @content_class.published
                             .where.not(id: @content.id)
                             .limit(4)
    render "contents/#{@content_type}/show"
  end

  private

  def set_content_class
    @content_class = Content.content_types[params[:klass]]
    raise ActiveRecord::RecordNotFound unless @content_class

    @content_type = params[:klass].singularize.downcase
  end
end
