FactoryBot.define do
  factory :early_access_user do
    sequence(:email) { |n| "user.#{n}@example.com" }
    source { "instant_signup" }
    user_description { "business_owner_or_self_employed" }
    reason_for_visit { "find_specific_answer" }
    found_chat { "govuk_website" }

    trait :revoked do
      revoked_at { Time.zone.now }
    end

    trait :shadow_banned do
      shadow_banned_at { Time.zone.now }
      shadow_banned_reason do
        "User attempted to jailbreak the system #{EarlyAccessUser::BANNABLE_ACTION_COUNT_THRESHOLD} times"
      end
      bannable_action_count { EarlyAccessUser::BANNABLE_ACTION_COUNT_THRESHOLD }
    end

    trait :restored do
      restored_at { Time.zone.now }
      restored_reason { "User was not being malicious" }
    end
  end
end
