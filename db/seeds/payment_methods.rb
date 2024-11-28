# Clear existing payment methods
PaymentMethod.destroy_all

# Create payment methods
[
  {
    name: 'mt_pelerin',
    instructions: 'Purchase Bitcoin directly with your credit card through Mt Pelerin.',
    settings: {
      api_token: ENV['MT_PELERIN_API_TOKEN'],
      base_url: 'https://buy.mtpelerin.com'
    }
  },
  {
    name: 'bitstack',
    instructions: 'Use Bitstack to send Bitcoin to this address.',
    settings: {
      api_key: ENV['BITSTACK_API_KEY']
    }
  },
  {
    name: 'ledger',
    instructions: 'Connect your Ledger wallet and send Bitcoin to this address.',
    settings: {}
  }
].each do |attrs|
  payment_method = PaymentMethod.create!(attrs)

  # Attach logo if exists in app/assets/images/payment_methods/
  logo_path = Rails.root.join('app/assets/images/payment_methods', "#{attrs[:name]}.png")
  if File.exist?(logo_path)
    payment_method.logo.attach(
      io: File.open(logo_path),
      filename: "#{attrs[:name]}.png",
      content_type: 'image/png'
    )
  end
end
