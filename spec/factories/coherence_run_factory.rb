FactoryBot.define do
  factory :coherence_run, class: "AnswerAnalysis::CoherenceRun" do
    answer
    score { 0.5 }
    status { "success" }
    reason { "The answer was okay." }

    trait :with_error do
      status { "error" }
      reason { nil }
      score { nil }
      error_message { "An error occurred during evaluation." }
    end
  end
end
