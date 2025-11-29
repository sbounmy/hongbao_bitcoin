module V3
  class HongBaosController < ApplicationController
    allow_unauthenticated_access only: %i[show form utxos]
    before_action :set_network
    layout :set_layout

    def show
      result = HongBaos::Scanner.call(params[:id])

      if result.success?
        @hong_bao = result.payload
        @quote = Content::Quote.published.random.first
      else
        redirect_to hong_baos_path, alert: result.error.user_message
      end
    end

    def form
      @hong_bao = HongBao.from_scan(params[:id])
      @current_step = (params[:step] || 1).to_i
      @steps = Step.for_show
    end

    def utxos
      @hong_bao = HongBao.from_scan(params[:id])
      @utxos = @hong_bao.balance.utxos_for_transaction(true)
      render "hong_baos/utxos"
    end

    private

    def set_network
      Current.network = Current.network_from_key(params[:id])
    end

    def set_layout
      if request.format.html?
        "btcdex"
      else
        false
      end
    end

  end
end
