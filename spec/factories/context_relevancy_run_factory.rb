FactoryBot.define do
  factory :context_relevancy_run, class: "AnswerAnalysis::ContextRelevancyRun" do
    answer
    score { 0.5 }
    reason { "The answer was okay." }
  end
end
