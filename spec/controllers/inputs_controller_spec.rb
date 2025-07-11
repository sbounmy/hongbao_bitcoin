# frozen_string_literal: true

require "rails_helper"

RSpec.describe InputsController, type: :controller do
  describe "GET #show" do
    it "renders the event template on event input" do
      get :show, params: { id: inputs(:pizza_day).id }
      expect(response).to be_successful
      expect(response).to render_template("inputs/events/show")
    end

    it "renders the theme template on theme input" do
      get :show, params: { id: inputs(:dollar).id }
      expect(response).to be_successful
      expect(response).to render_template("inputs/themes/show")
    end

    it "renders nothing on image input" do
      get :show, params: { id: inputs(:user).id }
      expect(response).to be_not_found
    end
  end
end
