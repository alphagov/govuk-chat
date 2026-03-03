FactoryBot.define do
  factory :answer_relevancy_run, class: "AnswerAnalysis::AnswerRelevancyRun" do
    answer
    score { 0.5 }
    status { "success" }
    reason { "The answer was okay." }
    llm_responses { {} }
    metrics { {} }
  end
end
