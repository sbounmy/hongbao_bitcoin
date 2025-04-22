FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password_digest { BCrypt::Password.create("password") }

    trait :john do
      email { "john@example.com" }
    end
  end
end
