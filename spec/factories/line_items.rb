FactoryBot.define do
  factory :line_item do
    order { nil }
    quantity { 1 }
    price { "9.99" }
    currency { "MyString" }
    stripe_price_id { "MyString" }
    metadata { "" }
  end
end
