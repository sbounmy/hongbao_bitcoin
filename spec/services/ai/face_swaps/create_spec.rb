require 'rails_helper'

RSpec.describe Ai::FaceSwaps::Create, type: :service do
  subject { described_class.call(params: face_swap_params, user:) }

  let(:user) { users(:john) }
  let(:face_swap_params) { { paper_id: papers(:one).id, image: papers(:one).image_front } }

  describe '#call', vcr: { cassette_name: "ai/face_swap/create_success" }  do
    it 'creates a new face swap record' do
      expect { subject }.to change(Ai::FaceSwap, :count).by(1)
      expect(Ai::FaceSwap.last).to have_attributes(
        user:,
        status: "processing",
        prompt: "Swap the face of the person in the image with the face of the person in the image",
        external_id: "acf661f4-9459-4d1d-9f1f-3e23e098adb4"
      )
    end
  end
end
