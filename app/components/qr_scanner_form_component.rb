# frozen_string_literal: true

class QrScannerFormComponent < ViewComponent::Base
  renders_one :header
  renders_one :instructions

  def initialize(url:, attribute: :scanned_key, auto_start: true, form_options: {}, fullscreen: false, title: nil, redirect_to: nil)
    @url = url
    @attribute = attribute
    @auto_start = auto_start
    @form_options = form_options
    @fullscreen = fullscreen
    @title = title || "Scan QR Code"
    @redirect_to = redirect_to
  end

  private

  attr_reader :url, :attribute, :auto_start, :form_options, :fullscreen, :title, :redirect_to

  def qr_reader_id
    @qr_reader_id ||= "qr-reader-#{SecureRandom.hex(4)}"
  end

  def qr_overlay_id
    @qr_overlay_id ||= "qr-overlay-#{SecureRandom.hex(4)}"
  end

  def form_data_attributes
    {
      controller: "qr-scanner",
      "qr-scanner-auto-start-value": auto_start,
      "qr-scanner-reader-id-value": qr_reader_id,
      "qr-scanner-overlay-id-value": qr_overlay_id
    }
  end

  def merged_form_options
    default_options = {
      url: url,
      method: :post,
      data: form_data_attributes,
      local: true
    }

    # Deep merge the data attributes if they exist in form_options
    if form_options[:data]
      default_options[:data] = default_options[:data].merge(form_options[:data])
      form_options.except(:data).merge(default_options)
    else
      form_options.merge(default_options)
    end
  end
end
