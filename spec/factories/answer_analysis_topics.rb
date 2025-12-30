FactoryBot.define do
  factory :answer_analysis_topics, class: "AnswerAnalysis::Topics" do
    answer
    primary_topic { "Primary Topic" }
    secondary_topic { "Secondary Topic" }
  end
end
