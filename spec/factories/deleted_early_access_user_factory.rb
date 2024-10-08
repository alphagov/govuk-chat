FactoryBot.define do
  factory :deleted_early_access_user do
    user_source { "instant_signup" }
    deletion_type { "unsubscribe" }
    user_created_at { Time.current }
  end
end
