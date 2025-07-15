module Likeable
  extend ActiveSupport::Concern

  included do
    # Ensure the including model has these columns:
    # - liker_ids: integer array
    # - likes_count: integer
    include ArrayColumns if !included_modules.include?(ArrayColumns)
    array_columns :liker_ids
  end

  def like!(user)
    return if liked_by?(user)

    transaction do
      current_liker_ids = Array(liker_ids)
      current_liker_ids << user.id
      new_liker_ids = current_liker_ids.uniq
      new_likes_count = new_liker_ids.size

      update_columns(
        liker_ids: new_liker_ids,
        likes_count: new_likes_count
      )
    end
  end

  def unlike!(user)
    return unless liked_by?(user)

    transaction do
      current_liker_ids = Array(liker_ids)
      current_liker_ids.delete(user.id)
      new_likes_count = current_liker_ids.size

      update_columns(
        liker_ids: current_liker_ids,
        likes_count: new_likes_count
      )
    end
  end

  def liked_by?(user)
    return false unless user
    (liker_ids || []).include?(user.id)
  end

  def like_toggle!(user)
    if liked_by?(user)
      unlike!(user)
    else
      like!(user)
    end
  end

  def likers
    User.where(id: liker_ids || [])
  end
end
