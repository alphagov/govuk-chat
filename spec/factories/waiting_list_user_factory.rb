FactoryBot.define do
  factory :waiting_list_user do
    sequence(:email) { |n| "user.#{n}@example.com" }
    source { "admin_added" }
    user_description { "business_owner_or_self_employed" }
    reason_for_visit { "find_specific_answer" }
    found_chat { "govuk_website" }
  end
end
