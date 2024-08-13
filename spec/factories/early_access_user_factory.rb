FactoryBot.define do
  factory :early_access_user do
    sequence(:email) { |n| "user.#{n}@example.com" }
    source { "instant_signup" }
    user_description { "business_owner_or_self_employed" }
    reason_for_visit { "find_specific_answer" }

    trait :revoked do
      revoked_at { Time.zone.now }
    end
  end
end
