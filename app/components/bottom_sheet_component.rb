# frozen_string_literal: true

class BottomSheetComponent < ApplicationComponent
  renders_one :trigger
  renders_one :header
  renders_one :footer, ->(title:, show_cancel: false) {
    FooterComponent.new(title:, show_cancel:)
  }

  def initialize(id:)
    @id = id
  end

  private

  attr_reader :id

  class FooterComponent < ApplicationComponent
    def initialize(title:, show_cancel:)
      @title = title
      @show_cancel = show_cancel
    end

    def call
      tag.div(class: "flex items-center justify-between px-4 py-3 border-t border-base-content/10 shrink-0") do
        safe_join([
          cancel_button,
          tag.span(@title, class: "text-sm text-base-content/70"),
          done_button
        ])
      end
    end

    private

    def cancel_button
      if @show_cancel
        tag.form(method: "dialog") do
          tag.button("Cancel", type: :submit, class: "btn btn-ghost btn-sm")
        end
      else
        # Empty spacer with same width as Done button to center title
        tag.div(class: "btn btn-ghost btn-sm invisible", aria: { hidden: true }) { "Done" }
      end
    end

    def done_button
      tag.form(method: "dialog") do
        tag.button("Done", type: :submit, class: "btn btn-ghost btn-sm text-primary font-semibold")
      end
    end
  end
end
