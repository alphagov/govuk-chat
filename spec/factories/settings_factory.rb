FactoryBot.define do
  factory :settings do
    singleton_guard { 0 }

    initialize_with { Settings.find_or_create_by(singleton_guard: 0) }
  end
end
