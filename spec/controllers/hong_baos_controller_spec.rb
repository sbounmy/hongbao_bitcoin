require 'rails_helper'

RSpec.describe HongBaosController, type: :controller do
  describe "GET #new" do
    it "returns a successful response", :vcr do
      get :new
      expect(response).to be_successful
    end
  end
end
