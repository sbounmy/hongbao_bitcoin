require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Client::Request do
  let(:base_url) { "https://api.example.com" }

  def get(url, **params)
    described_class.new(:get, url, **params)
  end

  def post(url, **params)
    described_class.new(:post, url, **params)
  end

  describe "#execute" do
    context "with GET requests" do
      let(:url) { "#{base_url}/users" }

      it "handles simple GET requests" do
        stub_request(:get, url)
          .to_return(status: 200, body: { users: [] }.to_json)

        response = get(url).execute

        expect(response).to be_a(Net::HTTPSuccess)
        expect(WebMock).to have_requested(:get, url)
          .with(headers: { "Content-Type" => "application/json" })
      end

      it "properly encodes query parameters" do
        stub_request(:get, url)
          .with(query: { limit: "10", offset: "20" })
          .to_return(status: 200, body: { users: [] }.to_json)

        get(url, limit: 10, offset: 20).execute

        expect(WebMock).to have_requested(:get, url)
          .with(query: { limit: "10", offset: "20" })
      end
    end

    context "with POST requests" do
      let(:url) { "#{base_url}/users" }

      it "handles JSON POST requests" do
        data = { name: "John", email: "john@example.com" }

        stub_request(:post, url)
          .with(body: data)
          .to_return(status: 201, body: data.merge(id: 1).to_json)

        post(url, **data).execute

        expect(WebMock).to have_requested(:post, url)
          .with(
            body: data,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles raw text POST requests" do
        url = "#{base_url}/tx"
        raw_hex = "0100000001..."

        stub_request(:post, url)
          .with(body: raw_hex, headers: { 'Content-Type' => 'text/plain' })
          .to_return(status: 200, body: "txid_123")

        request = post(url, body: raw_hex)
        response = request.execute

        expect(response.code).to eq("200")
        expect(response.body).to eq("txid_123")
        expect(WebMock).to have_requested(:post, url)
          .with(
            body: raw_hex,
            headers: { 'Content-Type' => 'text/plain' }
          )
      end

      it "handles multipart form data with files" do
        url = "#{base_url}/upload"
        file = double("ActiveStorage::Blob")
        allow(file).to receive(:download).and_return("file content")

        request = post(
          url,
          avatar: file,
          name: "John"
        )

        expect(request.headers["Content-Type"]).to eq('multipart/form-data')

        stub_request(:post, url)
          .with(headers: { 'Content-Type' => /multipart\/form-data/ })
          .to_return(status: 201, body: { success: true }.to_json)

        response = request.execute
        expect(response.code).to eq("201")

        expect(WebMock).to have_requested(:post, url)
          .with(headers: { 'Content-Type' => /multipart\/form-data/ })
      end

      it 'can pass content_type' do
        pending
        url = "#{base_url}/upload"
        file = active_storage_attachments(:satoshi_avatar)

        stub_request(:post, url)
        .with(headers: { 'Content-Type' => /multipart\/form-data/ })
        .to_return(status: 201, body: { success: true }.to_json)

        post(
          url,
          avatar: file.download,
          name: "John",
          content_type: "multipart/form-data"
        ).execute

        expect(WebMock).to have_requested(:post, url)
        .with(headers: { 'Content-Type' => /multipart\/form-data/ })
      end

      it "automatically detects different types of file objects" do
        url = "#{base_url}/upload"

        # Test with different file-like objects
        file_types = {
          active_storage: double("ActiveStorage::Blob", download: "content1"),
          file: File.new(__FILE__),
          tempfile: Tempfile.new("test"),
          stringio: StringIO.new("content2")
        }

        file_types.each do |type, file|
          request = post(url, avatar: file)
          expect(request.headers["Content-Type"]).to eq(Client::Request::CONTENT_TYPES[:MULTIPART])
        end
      end
    end

    context "with authorization" do
      let(:url) { "#{base_url}/secure" }
      it "adds authorization header when api_key is provided" do
        stub_request(:get, url)
          .with(headers: { "Authorization" => "Bearer test_key" })
          .to_return(status: 200, body: "{}")

        get(url).execute(api_key: "test_key")
        expect(WebMock).to have_requested(:get, url)
          .with(headers: {
            "Authorization" => "Bearer test_key",
            "Content-Type" => "application/json"
          })
      end
    end

    context "with custom headers" do
      let(:url) { "#{base_url}/users" }
      it "allows adding custom headers" do
        stub_request(:get, url)
          .with(headers: { "X-Custom" => "value" })
          .to_return(status: 200, body: "{}")

        get(url, headers: { "X-Custom" => "value" }).execute
        expect(WebMock).to have_requested(:get, url)
          .with(headers: {
            "X-Custom" => "value",
            "Content-Type" => "application/json"
          })
      end
    end

    context "with different HTTP methods" do
      let(:url) { "#{base_url}/users/1" }
      {
        put: Net::HTTP::Put,
        patch: Net::HTTP::Patch,
        delete: Net::HTTP::Delete
      }.each do |method, klass|
        it "handles #{method.upcase} requests" do
          request = described_class.new(method, url)
          stub_request(method, url)
            .to_return(status: 200, body: "{}")

          response = request.execute
          expect(response).to be_a(Net::HTTPSuccess)
          expect(WebMock).to have_requested(method, "#{base_url}/users/1")
        end
      end

      it "raises error for unsupported HTTP methods" do
        expect {
          described_class.new(:invalid, "#{base_url}/users")
        }.to raise_error(ArgumentError, /Unsupported HTTP method/)
      end
    end

    context "with SSL" do
      it "uses SSL for https URLs" do
        url = "https://api.example.com/users"
        stub_request(:get, url)
          .to_return(status: 200, body: "{}")

        get(url).execute
        expect(WebMock).to have_requested(:get, url)
      end

      it "doesn't use SSL for http URLs" do
        url = "http://api.example.com/users"
        stub_request(:get, url)
          .to_return(status: 200, body: "{}")

        get(url).execute
        expect(WebMock).to have_requested(:get, url)
      end
    end
  end
end
