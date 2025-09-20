# frozen_string_literal: true

module SavedHongBaos
  class ItemComponent < ApplicationComponent
    with_collection_parameter :saved_hong_bao
    attr_reader :saved_hong_bao, :view_type

    def initialize(saved_hong_bao:, view_type: :table)
      @saved_hong_bao = saved_hong_bao
      @view_type = view_type
      super
    end

    private

    def loading?
      saved_hong_bao.last_fetched_at.nil?
    end

    def show_percentage_change?
      saved_hong_bao.initial_spot && saved_hong_bao.initial_spot > 0 && saved_hong_bao.usd_change != 0
    end
  end
end
