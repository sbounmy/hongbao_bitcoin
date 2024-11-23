# bitcoin.rb

Bitcoin.network = if Rails.env.production?
  :bitcoin
else
  :testnet
end
