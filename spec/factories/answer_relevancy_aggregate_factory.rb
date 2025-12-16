FactoryBot.define do
  factory :answer_relevancy_aggregate, class: "AnswerAnalysis::AnswerRelevancyAggregate" do
    answer
    mean_score { 0.5 }
  end
end
