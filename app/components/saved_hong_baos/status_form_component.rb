module SavedHongBaos
  class StatusFormComponent < ApplicationComponent
    def initialize(saved_hong_bao:, status:, confirm_text:)
      @saved_hong_bao = saved_hong_bao
      @status = status
      @confirm_text = confirm_text
    end

    private

    attr_reader :saved_hong_bao, :status, :confirm_text
  end
end
