FactoryBot.define do
  factory :answer_analysis do
    answer
    primary_topic { "Primary Topic" }
    secondary_topic { "Secondary Topic" }
  end
end
