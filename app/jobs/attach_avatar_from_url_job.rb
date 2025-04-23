require "open-uri"

class AttachAvatarFromUrlJob < ApplicationJob
  queue_as :default

  def perform(user_id, picture_url)
    user = User.find(user_id)
    return if user.avatar.attached?
    downloaded_image = URI.open(picture_url)
    user.avatar.attach(io: downloaded_image, filename: "google_avatar.jpg")
  end
end
