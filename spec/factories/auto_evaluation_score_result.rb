FactoryBot.define do
  factory :auto_evaluation_score_result, class: "AutoEvaluation::ScoreResult" do
    skip_create

    score { 0.85.to_d }
    reason { "Most statements are relevant." }
    success { true }
    llm_responses { {} }
    metrics { {} }

    initialize_with { new(**attributes) }
  end
end
