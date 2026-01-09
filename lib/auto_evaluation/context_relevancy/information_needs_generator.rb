module AutoEvaluation
  class ContextRelevancy::InformationNeedsGenerator
    def self.call(...) = new(...).call

    def initialize(question:)
      @question = question
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("information_needs"), result.llm_response, result.metrics]
    end

  private

    attr_reader :question

    def llm_prompts
      Prompts.config.context_relevancy.fetch(:information_needs)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        question:,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
