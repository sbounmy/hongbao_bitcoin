# app/components/user_drawer_component.rb
class UserDrawerComponent < ApplicationComponent
  # Optionally initialize with user if needed later
  # def initialize(user: nil)
  #   @user = user
  # end

  # Define a method for the drawer ID for consistency
  def drawer_id
    "user-drawer-toggle" # Static ID for now
    # Or dynamically: helpers.dom_id(@user, :drawer_toggle) if user is passed
  end
end
