  class FaceSwapTask < ApplicationRecord
  belongs_to :user
  validates :task_id, presence: true, uniqueness: true
  validates :task_status, presence: true
  end
