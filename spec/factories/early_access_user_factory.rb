FactoryBot.define do
  factory :early_access_user do
    sequence(:email) { |n| "user.#{n}@example.com" }
    source { "instant_signup" }
  end
end
