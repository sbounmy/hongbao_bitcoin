FactoryBot.define do
  factory :order do
    user { nil }
    status { "MyString" }
    payment_provider { "MyString" }
    total_amount { "9.99" }
    currency { "MyString" }
    external_id { "MyString" }
  end
end
