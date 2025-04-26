class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :bundle
  has_many :messages, dependent: :destroy

  acts_as_chat

  def input_items
    bundle.input_items.where(id: input_item_ids)
  end

  def input_items=(input_items)
    self.input_item_ids = input_items.map(&:id)
  end
end
