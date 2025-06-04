FactoryBot.define do
  factory :settings do
    singleton_guard { 0 }
    instant_access_places { 100 }
    delayed_access_places { 100 }

    initialize_with { Settings.find_or_create_by(singleton_guard: 0) }
  end
end
