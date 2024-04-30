FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@dev.gov.uk" }
  end
end
