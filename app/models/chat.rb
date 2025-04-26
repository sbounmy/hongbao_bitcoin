class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :bundle
  has_many :messages, dependent: :destroy

  acts_as_chat

  def input_items
    bundle.input_items.where(id: input_item_ids)
  end
end
