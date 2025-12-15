module AutoEvaluation
  class AnswerRelevancy::VerdictsGenerator
    def self.call(...) = new(...).call

    def initialize(question_message:, statements:)
      @question_message = question_message
      @statements = statements
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("verdicts"), result.llm_response, result.metrics]
    end

  private

    attr_reader :question_message, :statements

    def llm_prompts
      Prompts.config
             .answer_relevancy
             .fetch(:verdicts)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        question: question_message,
        statements:,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
