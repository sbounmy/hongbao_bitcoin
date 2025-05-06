FactoryBot.define do
  factory :paper do
    name { "Paper #{SecureRandom.hex(4)}" }
    active { true }
    public { false }
    image_front { file_fixture("dollar_front.jpg") }
    image_back { file_fixture("dollar_back.jpg") }
  end
end
