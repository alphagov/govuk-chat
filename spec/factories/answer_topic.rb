FactoryBot.define do
  factory :answer_topic do
    answer
    primary { "Primary Topic" }
    secondary { "Secondary Topic" }
  end
end
