FactoryBot.define do
  factory :auto_evaluation_score_result, class: "AutoEvaluation::ScoreResult" do
    skip_create

    score { 0.85.to_d }
    sequence(:reason) { |n| "Reason #{n}" }
    success { true }
    sequence(:llm_responses) { |n| { "llm_response" => { "reason" => "Reason #{n}" } } }
    sequence(:metrics) { |n| { "llm_response" => { "duration" => n } } }

    initialize_with { new(**attributes) }
  end
end
