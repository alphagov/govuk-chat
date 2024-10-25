FactoryBot.define do
  factory :guardrails_multiple_checker_result, class: "Guardrails::MultipleChecker::Result" do
    initialize_with { new(**attributes) }

    llm_token_usage do
      {
        "prompt_tokens" => 13,
        "completion_tokens" => 7,
        "prompt_tokens_details" => { "cached_tokens" => 10 },
      }
    end

    llm_response do
      {
        "message": {
          "role": "assistant",
          "content": llm_guardrail_result,
        },
        "finish_reason": "stop",
      }
    end

    trait :pass do
      triggered { false }
      guardrails { [] }
      llm_guardrail_result { "False | None" }
    end

    trait :fail do
      triggered { true }
      guardrails { %w[political] }
      llm_guardrail_result { 'True | "3"' }
    end
  end
end
