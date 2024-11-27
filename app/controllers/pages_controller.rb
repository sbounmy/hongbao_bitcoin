class PagesController < ApplicationController
  allow_unauthenticated_access only: %i[bitcoin_test]
  def bitcoin_test
  end

  def bill_generator
  end
end
