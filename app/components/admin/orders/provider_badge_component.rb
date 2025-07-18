module Admin
  module Orders
    class ProviderBadgeComponent < ApplicationComponent
      def initialize(provider:)
        @provider = provider.to_s
      end

      def badge_classes
        base_classes = "badge"
        provider_classes = provider_class

        [ base_classes, provider_classes ].compact.join(" ")
      end

      def provider_name
        @provider.humanize
      end

      private

      attr_reader :provider

      def provider_class
        case provider
        when "stripe"
          "badge-primary"
        when "btcpay"
          "badge-accent"
        else
          "badge-neutral"
        end
      end
    end
  end
end
