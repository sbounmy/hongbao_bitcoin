class MobileHeaderComponent < ApplicationComponent
  renders_many :actions, MobileHeader::ActionComponent

  def initialize(title:, back_path: nil)
    @title = title
    @back_path = back_path
  end

  private

  attr_reader :title, :back_path
end
