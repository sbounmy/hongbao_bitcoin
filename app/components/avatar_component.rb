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

  def avatar_url
    if @user&.avatar&.attached?
      @user.avatar
    elsif @user.try(:avatar_url)
      @user.avatar_url
    else
      gravatar_url(@user.email)
    end
  end

  def link_url
    @user.try(:link_url)
  end

  def name
    @user.try(:name)
  end
end
