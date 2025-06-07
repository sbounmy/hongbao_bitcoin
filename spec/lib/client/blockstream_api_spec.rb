require 'rails_helper'

RSpec.describe Client::BlockstreamApi do
  let(:sample_address) { "bc1qemdhm8gy4uj4cuzryhujwxj2jt5arqz4rj9a6x" }
  let(:sample_txid) { "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b" }

  describe "initialization" do
    context "mainnet"  do
      let(:client) { Client::BlockstreamApi.new(dev: false) }

      it "sets the correct base URL for mainnet", vcr: { cassette_name: "blockstream_api/token" } do
        expect(client.base_url).to eq("https://blockstream.info/api")
      end
    end

    context "testnet" do
      let(:client) { Client::BlockstreamApi.new(dev: true) }

      it "sets the correct base URL for testnet", vcr: { cassette_name: "blockstream_api/token_dev" } do
        expect(client.base_url).to eq("https://blockstream.info/testnet/api")
      end
    end
  end

  describe "address endpoints" do
    let(:client) { Client::BlockstreamApi.new(dev: false) }

    context "get_address_transactions", vcr: { cassette_name: "blockstream_api/get_address_transactions" } do
      it "fetches address transactions as a list" do
        transactions = client.get_address_transactions(sample_address)

        expect(transactions).to be_a(Client::ListObject)
        expect(transactions.count).to be > 0
        expect(transactions[0].txid).to be_a(String)
        expect(transactions[0].status).to be_a(Client::Object)
      end
    end

    context "get_address_utxos", vcr: { cassette_name: "blockstream_api/get_address_utxos" } do
      it "fetches address UTXOs as a list" do
        utxos = client.get_address_utxos(sample_address)

        expect(utxos).to be_a(Client::ListObject)
        if utxos.count > 0
          expect(utxos[0].txid).to be_a(String)
          expect(utxos[0].value).to be_a(Integer)
          expect(utxos[0].status).to be_a(Client::Object)
        end
      end
    end
  end

  describe "transaction endpoints" do
    let(:client) { Client::BlockstreamApi.new(testnet: false) }

    context "get_transaction_hex", vcr: { cassette_name: "blockstream_api/get_transaction_hex" } do
      it "fetches transaction details" do
        transaction = client.get_transaction_hex(sample_txid)

        expect(transaction).to eql('01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000')
      end
    end
  end

  describe "block endpoints" do
    let(:client) { Client::BlockstreamApi.new(testnet: false) }

    context "get_tip_height", vcr: { cassette_name: "blockstream_api/get_tip_height" } do
      it "fetches current tip height" do
        height = client.get_tip_height

        expect(height.to_s).to match(/^\d+$/)
        expect(height).to be > 800000
      end
    end
  end

  describe ".url_for" do
    let(:client) { Client::BlockstreamApi.new(testnet: false) }

    it "returns the correct url for the given path" do
      expect(Client::BlockstreamApi.url_for("/tx/#{sample_txid}")).to eq("https://blockstream.info/api/tx/#{sample_txid}")
    end
  end
end
