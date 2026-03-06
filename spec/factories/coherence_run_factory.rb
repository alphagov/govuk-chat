FactoryBot.define do
  factory :coherence_run, class: "AnswerAnalysis::CoherenceRun" do
    answer
    score { 0.5 }
    status { "success" }
    reason { "The answer was okay." }
    llm_responses { {} }
    metrics { {} }
  end
end
