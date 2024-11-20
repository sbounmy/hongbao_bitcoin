module ApplicationHelper
  def gravatar_url(email, size = 40)
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=mp"
  end
end
