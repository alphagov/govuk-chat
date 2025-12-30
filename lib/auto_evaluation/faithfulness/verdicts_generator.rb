module AutoEvaluation
  class Faithfulness::VerdictsGenerator
    def self.call(...) = new(...).call

    def initialize(claims:, retrieval_context:)
      @claims = claims
      @retrieval_context = retrieval_context
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("verdicts"), result.llm_response, result.metrics]
    end

  private

    attr_reader :claims, :retrieval_context

    def llm_prompts
      Prompts.config
             .faithfulness
             .fetch(:verdicts)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        claims:,
        retrieval_context:,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
