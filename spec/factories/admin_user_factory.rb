FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin.user#{n}@dev.gov.uk" }

    trait :admin do
      permissions { %w[admin-area] }
    end

    trait :api_user do
      permissions { %w[api-user] }
    end
  end
end
