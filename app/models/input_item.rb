class InputItem < ApplicationRecord
  belongs_to :input
  belongs_to :bundle
  class Style < InputItem
  end

  class Theme < InputItem
  end

  class Image < InputItem
    has_one_attached :image
  end
end
