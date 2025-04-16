FactoryBot.define do
  factory :signon_user do
    sequence(:email) { |n| "admin.user#{n}@dev.gov.uk" }

    trait :admin do
      permissions { %w[admin-area] }
    end

    trait :conversation_api do
      permissions { %w[conversation-api] }
    end
  end
end
