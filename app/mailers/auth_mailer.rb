class AuthMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @verify_url = verify_magic_link_url(@user.magic_link_token)

    mail(
      to: @user.email,
      subject: "Your magic link for Hong Bao"
    )
  end
end
