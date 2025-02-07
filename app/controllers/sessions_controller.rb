class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    # Just renders the view
  end

  def create
    if user = User.find_by(email_address: params[:email_address].downcase)
      if user.authenticate(params[:password])
        start_new_session_for(user)
        redirect_to root_path, notice: "Signed in successfully!"
      else
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out successfully"
  end
end
