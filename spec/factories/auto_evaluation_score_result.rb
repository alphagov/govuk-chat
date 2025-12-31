FactoryBot.define do
  factory :auto_evaluation_score_result, class: "AutoEvaluation::ScoreResult" do
    score { 0.85 }
    reason { "Most statements are relevant." }
    success { true }
    llm_responses { {} }
    metrics { {} }

    initialize_with do
      new(
        score:,
        reason:,
        success:,
        llm_responses:,
        metrics:,
      )
    end
  end
end
