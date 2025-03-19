require "rails_helper"

RSpec.describe FaceSwap, type: :service, vcr: { cassette_name: "ai/face_swap/call_success" } do
  describe "#swap_faces" do
    it "swaps the faces" do
      image = active_storage_attachments(:dollar)
      face = active_storage_attachments(:satoshi)
      result = FaceSwap.call(image, face)
      expect(result).to be_success
    end
  end
end
