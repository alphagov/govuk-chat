FactoryBot.define do
  factory :settings_audit do
    user_id { SecureRandom.uuid }
    email { "user@factory" }
    action { "Instant access places increased by 10." }
    author_comment { "We ran out of places." }
  end
end
