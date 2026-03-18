module AutoEvaluation
  class ContextRelevancy::ReasonGenerator
    def self.call(...) = new(...).call

    def initialize(score:, question_message:, verdicts:)
      @score = score
      @question_message = question_message
      @verdicts = verdicts
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_message:, tool:)
      [result.evaluation_data.fetch("reason"), result.llm_response, result.metrics]
    end

  private

    attr_reader :score, :question_message, :verdicts

    def llm_prompts
      Prompts.config.context_relevancy.fetch(:reason)
    end

    def user_message
      sprintf(
        llm_prompts.fetch(:user_prompt),
        score:,
        question: question_message,
        unmet_needs: unmet_needs.join("\n"),
      )
    end

    def tool
      llm_prompts.fetch(:tool_spec)
    end

    def unmet_needs
      verdicts.select { |verdict| verdict["verdict"].strip.downcase == "no" }
              .map { |verdict| verdict["reason"] }
              .compact
    end
  end
end
