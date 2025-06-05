require 'rails_helper'

RSpec.describe Client::BlockstreamApi do
  let(:sample_address) { "bc1qemdhm8gy4uj4cuzryhujwxj2jt5arqz4rj9a6x" }
  let(:sample_txid) { "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b" }

  describe "initialization" do
    context "mainnet" do
      let(:client) { Client::BlockstreamApi.new(dev: false) }

      it "sets the correct base URL for mainnet" do
        expect(client.base_url).to eq("https://blockstream.info/api")
      end
    end

    context "testnet" do
      let(:client) { Client::BlockstreamApi.new(dev: true) }

      it "sets the correct base URL for testnet" do
        expect(client.base_url).to eq("https://blockstream.info/testnet/api")
      end
    end
  end

  describe "address endpoints" do
    let(:client) { Client::BlockstreamApi.new(dev: false) }

    context "get_address", vcr: { cassette_name: "blockstream_api/get_address" } do
      it "fetches address information" do
        address_info = client.get_address(sample_address)

        expect(address_info.address).to eq(sample_address)
        expect(address_info.chain_stats).to be_a(Client::Object)
        expect(address_info.chain_stats.funded_txo_count).to be_a(Integer)
        expect(address_info.chain_stats.funded_txo_sum).to be_a(Integer)
      end
    end

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

    context "get_transaction", vcr: { cassette_name: "blockstream_api/get_transaction" } do
      it "fetches transaction details" do
        transaction = client.get_transaction(sample_txid)

        expect(transaction.txid).to eq(sample_txid)
        expect(transaction.vin).to be_a(Array)
        expect(transaction.vin[0]).to be_a(Client::Object)
        expect(transaction.vout).to be_a(Array)
        expect(transaction.vout[0].value).to be_a(Integer)
        expect(transaction.status).to be_a(Client::Object)
      end
    end

    context "get_transaction_status", vcr: { cassette_name: "blockstream_api/get_transaction_status" } do
      it "fetches transaction status" do
        status = client.get_transaction_status(sample_txid)

        expect(status.confirmed).to be_a(TrueClass).or be_a(FalseClass)
        expect(status.block_height).to be_a(Integer) if status.confirmed
        expect(status.block_hash).to be_a(String) if status.confirmed
      end
    end
  end

  describe "block endpoints" do
    let(:client) { Client::BlockstreamApi.new(testnet: false) }

    context "get_tip_height", vcr: { cassette_name: "blockstream_api/get_tip_height" } do
      it "fetches current tip height" do
        height = client.get_tip_height

        expect(height).to match(/^\d+$/)
        expect(height.to_i).to be > 800000
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