class CardComponent < ApplicationComponent
  renders_one :back
  renders_one :front

  def initialize(title:, description:)
    @title = title
    @description = description
  end
end
