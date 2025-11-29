module Btcdex
  class DockComponent < ApplicationComponent
    renders_many :items, Dock::ItemComponent
  end
end
