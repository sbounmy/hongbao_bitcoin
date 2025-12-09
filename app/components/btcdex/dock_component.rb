module Btcdex
  class DockComponent < ApplicationComponent
    renders_many :items, Dock::ItemComponent
    renders_one :avatar
  end
end
