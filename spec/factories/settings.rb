FactoryBot.define do
  factory :settings do
    singleton_guard { 0 }
    instant_access_places { 100 }
    delayed_access_places { 100 }
    sign_up_enabled { true }
  end
end
