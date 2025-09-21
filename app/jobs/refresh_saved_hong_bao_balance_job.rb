class RefreshSavedHongBaoBalanceJob < ApplicationJob
  queue_as :default

  def perform(saved_hong_bao_id)
    SavedHongBao.find(saved_hong_bao_id).tap do |saved_hong_bao|
      balance = Balance.new(address: saved_hong_bao.address)
      saved_hong_bao.initial_sats ||= balance.transactions.first.amount
      saved_hong_bao.initial_spot ||= Spot.new(date: balance.transactions.first&.timestamp).to(:usd)
      saved_hong_bao.gifted_at ||= balance.transactions.first&.timestamp
      saved_hong_bao.current_sats = balance.satoshis
      saved_hong_bao.current_spot = Spot.current(:usd)
      saved_hong_bao.last_fetched_at = Time.current
      saved_hong_bao.save!
    end
  end
end
