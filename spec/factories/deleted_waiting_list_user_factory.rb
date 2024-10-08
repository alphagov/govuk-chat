FactoryBot.define do
  factory :deleted_waiting_list_user do
    user_source { "insufficient_instant_places" }
    deletion_type { "unsubscribe" }
    user_created_at { Time.current }
  end
end
