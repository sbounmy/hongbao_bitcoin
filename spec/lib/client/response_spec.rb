require 'rails_helper'

RSpec.describe Client::Response do
  let(:success_response) { Net::HTTPSuccess.new(1.0, "200", "OK") }
  let(:error_response) { instance_double(Net::HTTPBadRequest) }

  describe "#parse" do
    subject(:response) { described_class.new(success_response) }

    before do
      allow(success_response).to receive(:body).and_return(response_body)
    end

    context "with valid JSON" do
      let(:response_body) { { name: "pikachu" }.to_json }

      it "parses JSON response" do
        expect(response.send(:parse)).to eq({ "name" => "pikachu" })
      end
    end

    context "with empty response" do
      let(:response_body) { "" }

      it "returns empty hash" do
        expect(response.send(:parse)).to eq({})
      end
    end

    context "with nil response" do
      let(:response_body) { nil }

      it "returns empty hash" do
        expect(response.send(:parse)).to eq({})
      end
    end

    context "with non-JSON response" do
      let(:response_body) { "plain text" }

      it "returns raw body" do
        expect(response.send(:parse)).to eq("plain text")
      end
    end
  end

  describe "#handle" do
    context "with successful response" do
      before do
        allow(success_response).to receive(:body).and_return(response_body)
      end

      context "with JSON object response" do
        let(:response_body) { { name: "pikachu", type: "electric" }.to_json }

        it "converts response to Client::Object" do
          response = described_class.new(success_response)
          result = response.handle

          expect(result).to be_a(Client::Object)
          expect(result.name).to eq("pikachu")
          expect(result.type).to eq("electric")
        end

        context "with key specified" do
          let(:response_body) do
            {
              data: { name: "pikachu", type: "electric" },
              meta: { total: 1 }
            }.to_json
          end

          it "extracts specified key from response" do
            response = described_class.new(success_response, key: "data")
            result = response.handle

            expect(result).to be_a(Client::Object)
            expect(result.name).to eq("pikachu")
            expect(result.type).to eq("electric")
          end
        end
      end

      context "with array response" do
        let(:response_body) do
          {
            results: [
              { name: "pikachu", type: "electric" },
              { name: "charmander", type: "fire" }
            ],
            total: 2
          }.to_json
        end

        it "converts array response to ListObject" do
          response = described_class.new(success_response, key: "results")
          result = response.handle

          expect(result).to be_a(Client::ListObject)
          expect(result.count).to eq(2)
          expect(result[0].name).to eq("pikachu")
          expect(result[1].name).to eq("charmander")
          expect(result.total).to eq(2)
        end
      end

      context "with non-JSON response" do
        let(:response_body) { "plain text response" }

        it "returns raw body" do
          response = described_class.new(success_response)
          result = response.handle

          expect(result).to eq("plain text response")
        end
      end

      context "with empty response" do
        let(:response_body) { "" }

        it "returns empty hash" do
          response = described_class.new(success_response)
          result = response.handle

          expect(result).to be_a(Client::Object)
        end
      end
    end

    context "with error response" do
      before do
        allow(error_response).to receive(:code).and_return("400")
        allow(error_response).to receive(:message).and_return("Bad Request")
        allow(error_response).to receive(:body).and_return(error_body)
      end

      context "with JSON error response" do
        let(:error_body) { { error: "Invalid parameters" }.to_json }

        it "raises error with message" do
          response = described_class.new(error_response)

          expect { response.handle }.to raise_error(
            RuntimeError,
            "API Error: 400 Bad Request: Invalid parameters"
          )
        end
      end

      context "with plain text error response" do
        let(:error_body) { "Something went wrong" }

        it "raises error with body" do
          response = described_class.new(error_response)

          expect { response.handle }.to raise_error(
            RuntimeError,
            "API Error: 400 Bad Request: Something went wrong"
          )
        end
      end
    end
  end
end
