module Checkout
  class Base < ApplicationService
    def self.for(provider_name, action)
      "Checkout::#{provider_name.to_s.classify}::#{action.to_s.classify}".constantize
    rescue NameError
      nil # Return nil if the class doesn't exist
    end
  end
end
