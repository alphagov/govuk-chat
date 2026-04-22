FactoryBot.define do
  factory :guardrails_multiple_checker_result, class: "AnswerComposition::MultipleGuardrail::Checker::Result" do
    initialize_with { new(**attributes) }

    llm_prompt_tokens { 13 }
    llm_completion_tokens { 7 }
    llm_cached_tokens { 10 }
    model { BedrockModels.model_id(AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL) }

    llm_response do
      content = Anthropic::Models::TextBlock.new(
        type: :text,
        text: llm_guardrail_result,
      )

      usage = Anthropic::Models::Usage.new(
        input_tokens: llm_prompt_tokens,
        output_tokens: llm_completion_tokens,
        cache_read_input_tokens: llm_cached_tokens,
      )

      Anthropic::Models::Message.new(
        id: "msg-id",
        model:,
        role: :assistant,
        content:,
        stop_reason: :end_turn,
        usage:,
        type: :message,
      ).to_h
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
