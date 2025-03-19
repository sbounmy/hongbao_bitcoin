require 'rails_helper'

RSpec.describe Ai::FaceSwap::Create, type: :service do
  describe '#call' do
    it 'creates a new face swap record' do
      expect { subject.call }.to change(Ai::FaceSwap, :count).by(1)
    end
  end
end
