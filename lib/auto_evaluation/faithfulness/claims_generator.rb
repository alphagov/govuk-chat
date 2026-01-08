module AutoEvaluation
  class Faithfulness::ClaimsGenerator
    def self.call(...) = new(...).call

    def initialize(answer_message:)
      @answer_message = answer_message
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("claims"), result.llm_response, result.metrics]
    end

  private

    attr_reader :answer_message

    def llm_prompts
      Prompts.config
             .faithfulness
             .fetch(:claims)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        answer: answer_message,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
