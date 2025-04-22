# frozen_string_literal: true

class AvatarComponent < ViewComponent::Base
  # Specifies that when rendering a collection, each item should be passed as the 'contributor' argument.
  with_collection_parameter :user

  # Required:
  #   contributor: An object or hash containing contributor details.
  #              Must respond to :name and :avatar_url.
  #              May respond to :link_url.
  def initialize(user:)
    @user = user
  end

  delegate :name, :avatar_url, :link_url, to: :@user
end
