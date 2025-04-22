FactoryBot.define do
  factory :ai_theme, class: 'Ai::Theme' do
    sequence(:title) { |n| "Theme #{n}" }
    sequence(:path) { |n| "theme-#{n}" }

    trait :with_custom_colors do
      ui { {
        'color-primary' => '#FF5733',
        'color-secondary' => '#33FF57',
        'color-accent' => '#5733FF',
        'depth' => '3'
      } }
    end
  end
end
