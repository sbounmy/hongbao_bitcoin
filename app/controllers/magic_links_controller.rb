class MagicLinksController < ApplicationController
  allow_unauthenticated_access only: %i[create verify]

  def create
    @user = User.find_or_initialize_by(email_address: magic_link_params[:email_address].downcase)

    if @user.save
      @user.generate_magic_link
      AuthMailer.magic_link(@user).deliver_later

      render turbo_stream: turbo_stream.update(
        "magic_link_form",
        partial: "magic_links/success",
        locals: { email_address: @user.email_address }
      )
    else
      render turbo_stream: turbo_stream.update(
        "magic_link_form",
        partial: "magic_links/form",
        locals: { user: @user }
      )
    end
  end

  def verify
    @user = User.find_by(magic_link_token: params[:id])

    if @user&.valid_magic_link?(params[:id])
      # Use the authentication concern to create session
      start_new_session_for(@user)

      # Clear the used magic link
      @user.clear_magic_link!

      # Redirect to the saved URL or default route
      redirect_to after_authentication_url, notice: "Welcome back!"
    else
      redirect_to root_path, alert: "Invalid or expired magic link. Please request a new one."
    end
  end

  private

  def magic_link_params
    params.permit(:email_address)
  end
end
