FactoryBot.define do
  factory :signon_user do
    sequence(:email) { |n| "signon.user#{n}@dev.gov.uk" }
    sequence(:name) { |n| "Signon User #{n}" }

    trait :admin do
      permissions { %w[admin-area] }
    end

    trait :conversation_api do
      permissions { %w[conversation-api] }
    end

    trait :web_chat do
      permissions { %w[web-chat] }
    end
  end
end
