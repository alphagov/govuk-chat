module AnswerComposition::MultipleGuardrail
  class ResponseError < StandardError
    attr_reader :llm_response, :llm_guardrail_result, :llm_prompt_tokens,
                :llm_completion_tokens, :llm_cached_tokens, :model

    def initialize(message,
                   llm_response,
                   llm_guardrail_result,
                   llm_prompt_tokens,
                   llm_completion_tokens,
                   llm_cached_tokens,
                   model)
      super(message)
      @llm_response = llm_response
      @llm_guardrail_result = llm_guardrail_result
      @llm_prompt_tokens = llm_prompt_tokens
      @llm_completion_tokens = llm_completion_tokens
      @llm_cached_tokens = llm_cached_tokens
      @model = model
    end
  end
end
