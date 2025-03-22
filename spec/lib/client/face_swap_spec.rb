require "rails_helper"

RSpec.describe Client::FaceSwap, type: :client do
  let(:client) { described_class.new }

  describe "#swap_faces" do
    let(:image) { active_storage_attachments(:dollar) }
    let(:face) { active_storage_attachments(:satoshi) }
    let(:webhook_url) { "https://stephane.hongbaob.tc/ai/face_swap/done" }

    context "with successful response", vcr: { cassette_name: "ai/face_swap/swap_faces_success" } do
      it "swaps the faces" do
        response = client.swap_faces(
          files: {
            source_image: image,
            face_image: face
          },
          webhook: webhook_url
        )

        expect(response).to be_a(Client::Object)
      end
    end
  end
end
