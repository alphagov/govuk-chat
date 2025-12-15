FactoryBot.define do
  factory :answer_topics do
    answer
    primary_topic { "Primary Topic" }
    secondary_topic { "Secondary Topic" }
  end
end
