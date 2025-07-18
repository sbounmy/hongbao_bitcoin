# frozen_string_literal: true

class Token < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  validates :quantity, presence: true, numericality: { only_integer: true }

  after_create :update_user_tokens_sum
  after_destroy :update_user_tokens_sum

  private

  def update_user_tokens_sum
    user.update_column(:tokens_sum, user.tokens.sum(:quantity))
  end
end
