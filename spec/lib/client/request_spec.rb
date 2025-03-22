require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Client::Request do
  let(:base_url) { "https://api.example.com" }

  describe "#execute" do
    context "with GET requests" do
      it "handles simple GET requests" do
        request = described_class.new(:get, "#{base_url}/users")
        stub_request(:get, "#{base_url}/users")
          .to_return(status: 200, body: { users: [] }.to_json)

        response = request.execute
        expect(response).to be_a(Net::HTTPSuccess)
        expect(WebMock).to have_requested(:get, "#{base_url}/users")
          .with(headers: { "Content-Type" => "application/json" })
      end

      it "properly encodes query parameters" do
        request = described_class.new(
          :get,
          "#{base_url}/users",
          limit: 10,
          offset: 20
        )

        stub_request(:get, "#{base_url}/users")
          .with(query: { limit: "10", offset: "20" })
          .to_return(status: 200, body: { users: [] }.to_json)

        request.execute
        expect(WebMock).to have_requested(:get, "#{base_url}/users")
          .with(query: { limit: "10", offset: "20" })
      end
    end

    context "with POST requests" do
      it "handles JSON POST requests" do
        data = { name: "John", email: "john@example.com" }
        request = described_class.new(:post, "#{base_url}/users", **data)

        stub_request(:post, "#{base_url}/users")
          .with(body: data)
          .to_return(status: 201, body: data.merge(id: 1).to_json)

        request.execute
        expect(WebMock).to have_requested(:post, "#{base_url}/users")
          .with(
            body: data,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles multipart form data with files" do
        file = double("ActiveStorage::Blob")
        allow(file).to receive(:download).and_return("file content")

        request = described_class.new(
          :post,
          "#{base_url}/upload",
          content_type: Client::Request::CONTENT_TYPES[:MULTIPART],
          files: { avatar: file },
          name: "John"
        )

        puts "request: #{request.inspect}"
        stub_request(:post, "#{base_url}/upload")
          .with(
            headers: { 'Content-Type' => /multipart\/form-data/ }
          )
          .to_return(status: 201, body: { success: true }.to_json)

        response = request.execute

        expect(response.code).to eq("201")

        expect(WebMock).to have_requested(:post, "#{base_url}/upload")
          .with(
            headers: { 'Content-Type' => /multipart\/form-data/ },
          )
      end
    end

    context "with authorization" do
      it "adds authorization header when api_key is provided" do
        request = described_class.new(:get, "#{base_url}/secure")
        stub_request(:get, "#{base_url}/secure")
          .with(headers: { "Authorization" => "Bearer test_key" })
          .to_return(status: 200, body: "{}")

        request.execute(api_key: "test_key")
        expect(WebMock).to have_requested(:get, "#{base_url}/secure")
          .with(headers: {
            "Authorization" => "Bearer test_key",
            "Content-Type" => "application/json"
          })
      end
    end

    context "with custom headers" do
      it "allows adding custom headers" do
        request = described_class.new(
          :get,
          "#{base_url}/users",
          headers: { "X-Custom" => "value" }
        )

        stub_request(:get, "#{base_url}/users")
          .with(headers: { "X-Custom" => "value" })
          .to_return(status: 200, body: "{}")

        request.execute
        expect(WebMock).to have_requested(:get, "#{base_url}/users")
          .with(headers: {
            "X-Custom" => "value",
            "Content-Type" => "application/json"
          })
      end
    end

    context "with different HTTP methods" do
      {
        put: Net::HTTP::Put,
        patch: Net::HTTP::Patch,
        delete: Net::HTTP::Delete
      }.each do |method, klass|
        it "handles #{method.upcase} requests" do
          request = described_class.new(method, "#{base_url}/users/1")
          stub_request(method, "#{base_url}/users/1")
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
        request = described_class.new(:get, "https://api.example.com/users")
        stub_request(:get, "https://api.example.com/users")
          .to_return(status: 200, body: "{}")

        request.execute
        expect(WebMock).to have_requested(:get, "https://api.example.com/users")
      end

      it "doesn't use SSL for http URLs" do
        request = described_class.new(:get, "http://api.example.com/users")
        stub_request(:get, "http://api.example.com/users")
          .to_return(status: 200, body: "{}")

        request.execute
        expect(WebMock).to have_requested(:get, "http://api.example.com/users")
      end
    end
  end
end
