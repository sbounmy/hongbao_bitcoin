class MobileHeaderComponent < ApplicationComponent
  def initialize(title:, back_path: nil, actions: [])
    @title = title
    @back_path = back_path
    @actions = actions
  end

  private

  attr_reader :title, :back_path, :actions
end