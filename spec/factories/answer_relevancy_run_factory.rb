FactoryBot.define do
  factory :answer_relevancy_run, class: "AnswerAnalysis::AnswerRelevancyRun" do
    association :aggregate, factory: :answer_relevancy_aggregate
    score { 0.5 }
    reason { "The answer was okay." }
  end
end
