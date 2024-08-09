FactoryBot.define do
  factory :passwordless_session, class: "Passwordless::Session" do
    authenticatable factory: :early_access_user

    trait :timed_out do
      timeout_at { 100.days.ago }
    end

    trait :claimed do
      claimed_at { 1.day.ago }
    end
  end
end
