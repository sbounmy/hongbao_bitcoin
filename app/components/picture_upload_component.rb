class PictureUploadComponent < ApplicationComponent
  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form
end
