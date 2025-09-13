FactoryBot.define do
  factory :content do
    slug { "MyString" }
    content_type { "MyString" }
    title { "MyString" }
    h1 { "MyString" }
    meta_description { "MyText" }
    data { "" }
    published_at { "2025-09-06 15:32:39" }
    impressions_count { 1 }
    clicks_count { 1 }
  end
end
