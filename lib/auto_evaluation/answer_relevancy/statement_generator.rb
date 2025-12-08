module AutoEvaluation
  class AnswerRelevancy::StatementGenerator
    def self.call(...) = new(...).call

    def initialize(answer_message:)
      @answer_message = answer_message
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, json_schema)
      [result.evaluation_data.fetch("statements"), result.llm_response, result.metrics]
    end

  private

    attr_reader :answer_message

    def llm_prompts
      Prompts.config
             .answer_relevancy
             .fetch(:statements)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        answer: answer_message,
      )
    end

    def json_schema
      llm_prompts.fetch(:json_schema)
    end
  end
end
