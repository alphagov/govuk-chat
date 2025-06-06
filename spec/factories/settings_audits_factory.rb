FactoryBot.define do
  factory :settings_audit do
    user { build :signon_user }
    action { "Instant access places increased by 10." }
    author_comment { "We ran out of places." }
  end
end
