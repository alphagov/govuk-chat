FactoryBot.define do
  factory :signon_user do
    sequence(:email) { |n| "admin.user#{n}@dev.gov.uk" }

    trait :admin do
      permissions { %w[admin-area] }
    end
  end
end
