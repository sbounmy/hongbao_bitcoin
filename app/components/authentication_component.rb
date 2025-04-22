class AuthenticationComponent < ApplicationComponent
  def initialize(user:)
    @user = user
  end

  private

  def component_for_user
    if @user.new_record? && @user.email.blank?
      Authentication::EmailComponent.new(user: @user)
    elsif @user.new_record? && @user.email.present?
      Authentication::UserComponent.new(user: @user)
    else
      Authentication::SessionComponent.new(user: @user)
    end
  end
end
