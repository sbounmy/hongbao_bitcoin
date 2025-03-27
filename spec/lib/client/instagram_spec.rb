require "rails_helper"

RSpec.describe Client::Instagram do
  let(:client) { described_class.new }

  describe "#me_media" do
    context "when the request is successful", vcr: { cassette_name: "instagram/me_media_success" } do
      it "fetches media from Instagram API" do
        result = client.me_media
        expect(result).to be_a(Client::ListObject)
        expect(result.data).to be_an(Array)
        expect(result.data.first).to be_a(Client::Object) if result.data.any?
      end
    end
    context "when the request is erroneous", vcr: { cassette_name: "instagram/me_media_error" } do
      it "raises an API error" do
        expect {
          client.fetch({ fields: "test", access_token: "wrong access token"  })
        }.to raise_error(RuntimeError, /API Error: 400 Bad Request: Sorry, this content isn't available right now/)
      end
    end
  end
end
