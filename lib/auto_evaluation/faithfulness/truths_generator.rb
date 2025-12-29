module AutoEvaluation
  class Faithfulness::TruthsGenerator
    def self.call(...) = new(...).call

    def initialize(retrieval_context:)
      @retrieval_context = retrieval_context
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("truths"), result.llm_response, result.metrics]
    end

  private

    attr_reader :retrieval_context

    def llm_prompts
      Prompts.config
             .faithfulness
             .fetch(:truths)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        retrieval_context:,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
