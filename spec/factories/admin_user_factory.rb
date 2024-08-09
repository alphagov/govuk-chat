FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin.user#{n}@dev.gov.uk" }

    trait :admin do
      permissions { %w[admin-area] }
    end
  end
end
