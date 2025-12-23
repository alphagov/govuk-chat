FactoryBot.define do
  factory :answer_topics, class: "AnswerAnalysis::AnswerTopics" do
    answer
    primary_topic { "Primary Topic" }
    secondary_topic { "Secondary Topic" }
  end
end
