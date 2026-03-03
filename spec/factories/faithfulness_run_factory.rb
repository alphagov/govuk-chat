FactoryBot.define do
  factory :faithfulness_run, class: "AnswerAnalysis::FaithfulnessRun" do
    answer
    score { 0.5 }
    status { "success" }
    reason { "The answer was okay." }
    llm_responses { {} }
    metrics { {} }
  end
end
