module AutoEvaluation
  class AnswerRelevancy::ReasonGenerator
    def self.call(...) = new(...).call

    def initialize(question_message:, verdicts:, score:)
      @question_message = question_message
      @verdicts = verdicts
      @score = score
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("reason"), result.llm_response, result.metrics]
    end

  private

    attr_reader :question_message, :verdicts, :score

    def llm_prompts
      Prompts.config
             .answer_relevancy
             .fetch(:reason)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        score:,
        unsuccessful_verdicts_reasons:,
        question: question_message,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end

    def unsuccessful_verdicts_reasons
      verdicts.select { |verdict| verdict["verdict"].strip.downcase == "no" }
              .map { |verdict| verdict["reason"] }
    end
  end
end
