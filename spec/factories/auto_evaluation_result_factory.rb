FactoryBot.define do
  factory :auto_evaluation_result, class: "AutoEvaluation::Result" do
    skip_create

    score { 0.85.to_d }
    status { "success" }
    sequence(:reason) { |n| "Reason #{n}" }
    error_message { nil }
    sequence(:llm_responses) { |n| { "llm_response" => { "reason" => "Reason #{n}" } } }
    sequence(:metrics) { |n| { "llm_response" => { "duration" => n } } }

    trait :with_error do
      status { "error" }
      sequence(:error_message) { |n| "Error message #{n}" }
      score { nil }
    end

    initialize_with { new(**attributes) }
  end
end
