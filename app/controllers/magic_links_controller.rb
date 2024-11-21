class MagicLinksController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
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

  private

  def magic_link_params
    params.permit(:email_address)
  end
end
