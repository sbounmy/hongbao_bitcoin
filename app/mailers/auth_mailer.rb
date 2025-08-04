class AuthMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @verify_url = verify_magic_link_url(@user.magic_link_token)

    mail(
      to: @user.email,
      subject: "Your magic link for Hong Bao"
    )
  end

  def account_created(user)
    @user = user

    mail(
      to: @user.email,
      subject: "Account Created - Set Your Password"
    )
  end
end
