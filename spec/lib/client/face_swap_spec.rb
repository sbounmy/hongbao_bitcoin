require "rails_helper"

RSpec.describe Client::FaceSwap, type: :client do
  let(:client) { described_class.new }

  describe "#swap_faces" do
    let(:image) { active_storage_attachments(:dollar_paper_front) }
    let(:face) { active_storage_attachments(:satoshi_avatar) }
    let(:webhook_url) { "https://stephane.hongbaob.tc/ai/face_swap/done" }

    context "with successful response", vcr: { cassette_name: "ai/face_swap/swap_faces_success" } do
      it "swaps the faces" do
        response = client.swap_faces(
          source_image: image,
          face_image: face,
          webhook: webhook_url
        )

        expect(response).to be_a(Client::Object)
        expect(response.task_id).to eq("c0dfe2d265372d93e0f553a23defa215")
      end
    end
  end
end
