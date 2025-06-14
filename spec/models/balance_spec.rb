require "rails_helper"

describe Balance do
  let(:balance) { Balance.new(address: "bc1qemdhm8gy4uj4cuzryhujwxj2jt5arqz4rj9a6x") }

  describe "#transactions", vcr: { cassette_name: "balance/transactions" } do
    it "returns the transactions for the balance" do
      expect(balance.transactions).to be_an(Array)
      transaction = balance.transactions.last
      expect(transaction.id).to eq("8aaa32840db9a9c5ace5283e50cf12d7394f7a2d44efeb97f202f95d453b2aff")
      expect(transaction.timestamp.utc.to_s).to eq("2025-01-26 08:49:19 UTC")
      expect(transaction.amount).to eq(4919)
      expect(transaction.address).to eq("bc1qemdhm8gy4uj4cuzryhujwxj2jt5arqz4rj9a6x")
      expect(transaction.deposit?).to be_truthy
      expect(transaction.withdrawal?).to be_falsey
      expect(transaction.confirmations).to eq(19249)
      expect(transaction.block_height).to eq(880879)
      expect(transaction.script).to eq("0014cedb7d9d04af255c704325f9271a4a92e9d18055")
    end
  end

  describe "#utxos_for_transaction", vcr: { cassette_name: "balance/utxos_for_transaction" } do
    it "returns full utxos with true" do
      expect(balance.utxos_for_transaction(true)).to be_an(Array)
      utxo = balance.utxos_for_transaction(true).last
      expect(utxo[:txid]).to eq("8aaa32840db9a9c5ace5283e50cf12d7394f7a2d44efeb97f202f95d453b2aff")
      expect(utxo[:vout]).to eq(0)
      expect(utxo[:script]).to eq('0014cedb7d9d04af255c704325f9271a4a92e9d18055')
    end

    it "returns utxos with false" do
      expect(balance.utxos_for_transaction).to be_an(Array)
      utxo = balance.utxos_for_transaction.last
      expect(utxo[:txid]).to eq("8aaa32840db9a9c5ace5283e50cf12d7394f7a2d44efeb97f202f95d453b2aff")
      expect(utxo[:vout]).to eq(0)
      expect(utxo[:script]).to be_blank
    end
  end
end
