class CalEmbedComponent < ApplicationComponent
  def initialize(cal_link: "sbounmy/hongbao", namespace: "hongbao")
    @cal_link = cal_link
    @namespace = namespace
  end

  private

  attr_reader :cal_link, :namespace

  def element_id
    "my-cal-inline-#{namespace}"
  end
end
