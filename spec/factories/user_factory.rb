FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@dev.gov.uk" }

    trait :admin do
      permissions { %w[admin-area] }
    end
  end
end
