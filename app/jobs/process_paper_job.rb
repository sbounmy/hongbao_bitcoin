require "net/http"
require "json"

class ProcessPaperJob < ApplicationJob
  queue_as :default

  def perform(chat)
    @chat = chat
    RubyLLM.edit(
      prompt:,
      image:,
    )
  end

  private

  def prompt
    input_items.map(&:prompt).join("\n")
  end

  def image
    [
      @chat.input_items.where(type: "Input::Theme").first.download,
      @chat.input_items.where(type: "Input::Image").first.download
    ]
  end
end
