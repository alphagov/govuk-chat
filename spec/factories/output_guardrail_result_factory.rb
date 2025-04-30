FactoryBot.define do
  factory :guardrails_multiple_checker_result, class: "Guardrails::MultipleChecker::Result" do
    initialize_with { new(**attributes) }

    llm_prompt_tokens { 13 }
    llm_completion_tokens { 7 }
    llm_cached_tokens { 10 }

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
      guardrails { { political: false, appropriate_language: false } }
      llm_guardrail_result { "False | None" }
    end

    trait :fail do
      triggered { true }
      guardrails { { political: true, appropriate_language: false } }
      llm_guardrail_result { 'True | "3"' }
    end
  end
end
