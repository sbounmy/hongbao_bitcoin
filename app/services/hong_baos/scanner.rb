module HongBaos
  class Scanner < ApplicationService
    class ScanError < StandardError
      attr_reader :user_message

      def initialize(message, user_message: nil)
        super(message)
        @user_message = user_message || message
      end
    end

    def call(scanned_key)
      @scanned_key = scanned_key

      return failure(ScanError.new("Scanned key is blank", user_message: "Invalid QR code")) unless @scanned_key.present?

      extract_address_if_url
      create_hong_bao

      success(@hong_bao)
    rescue => e
      Rails.logger.error("HongBao scanning failed: #{e.message}")
      failure(e)
    end

    private

    def extract_address_if_url
      return unless @scanned_key.start_with?("http")

      match = @scanned_key.match(%r{/addrs/([^/]+)$})

      if match
        @scanned_key = match[1]
      else
        raise ScanError.new(
          "Invalid URL format: #{@scanned_key}",
          user_message: "This QR code contains a URL that is not a Bitcoin wallet"
        )
      end
    end

    def create_hong_bao
      @hong_bao = HongBao.from_scan(@scanned_key)

      unless @hong_bao.address.present?
        raise ScanError.new(
          "HongBao creation failed for key: #{@scanned_key}",
          user_message: "Invalid QR code"
        )
      end
    end
  end
end
