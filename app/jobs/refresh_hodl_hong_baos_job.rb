class RefreshHodlHongBaosJob < ApplicationJob
  queue_as :default

  def perform
    # Find all CREATED and HODL hong baos that haven't been refreshed in 24 hours
    SavedHongBao.needs_refresh.find_each do |saved_hong_bao|
      RefreshSavedHongBaoBalanceJob.perform_later(saved_hong_bao.id)
    end
  end
end
