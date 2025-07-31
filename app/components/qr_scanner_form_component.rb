# frozen_string_literal: true

class QrScannerFormComponent < ViewComponent::Base
  def initialize(url:, attribute: :scanned_key, auto_start: true, form_options: {})
    @url = url
    @attribute = attribute
    @auto_start = auto_start
    @form_options = form_options
  end

  private

  attr_reader :url, :attribute, :auto_start, :form_options

  def qr_reader_id
    @qr_reader_id ||= "qr-reader-#{SecureRandom.hex(4)}"
  end

  def form_data_attributes
    {
      controller: "qr-scanner",
      "qr-scanner-auto-start-value": auto_start,
      "qr-scanner-reader-id-value": qr_reader_id
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
