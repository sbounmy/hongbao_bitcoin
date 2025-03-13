
require 'rails_helper'

RSpec.describe Ai::Designs::Create, type: :model do
  describe "#call" do
    it "creates a new design" do
      expect { described_class.call }.to change(Ai::Generation, :count).by(1)
    end
  end
end
