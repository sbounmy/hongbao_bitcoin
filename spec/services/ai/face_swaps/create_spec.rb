require 'rails_helper'

RSpec.describe Ai::FaceSwaps::Create, type: :service do
  subject { described_class.call(params: face_swap_params, user:) }

  let(:user) { users(:john) }
  let(:face_swap_params) { { paper_id: papers(:dollar).id, image: papers(:dollar).image_front } }

  describe '#call', vcr: { cassette_name: "ai/face_swap/create_success" } do
    it 'creates a new face swap record' do
      expect(papers(:dollar).image_front.attached?).to be_truthy
      expect(papers(:dollar).image_front.download).to be_truthy

      expect { subject }.to change(Ai::FaceSwap, :count).by(1)
      expect(Ai::FaceSwap.last).to have_attributes(
        user:,
        status: "processing",
        prompt: "Swap the face of the person in the image with the face of the person in the image",
        external_id: "c6493e510a7c430f241e62d0b9161f51"
      )
    end
  end
end
