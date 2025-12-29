module AutoEvaluation
  class Faithfulness::VerdictsGenerator
    def self.call(...) = new(...).call

    def initialize(claims:, truths:)
      @claims = claims
      @truths = truths
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("verdicts"), result.llm_response, result.metrics]
    end

  private

    attr_reader :claims, :truths

    def llm_prompts
      Prompts.config
             .faithfulness
             .fetch(:verdicts)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        claims:,
        retrieval_context: truths.join("\n\n"),
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
