FactoryBot.define do
  factory :early_access_user do
    sequence(:email) { |n| "user.#{n}@example.com" }
  end
end
