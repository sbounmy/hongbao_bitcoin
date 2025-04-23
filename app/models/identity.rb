# frozen_string_literal: true

class Identity < ApplicationRecord
  belongs_to :user

  validates :provider_name, presence: true
  validates :provider_uid, presence: true, uniqueness: { scope: :provider_name }
end
