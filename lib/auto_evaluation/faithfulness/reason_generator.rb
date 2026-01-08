module AutoEvaluation
  class Faithfulness::ReasonGenerator
    def self.call(...) = new(...).call

    def initialize(score:, verdicts:)
      @score = score
      @verdicts = verdicts
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("reason"), result.llm_response, result.metrics]
    end

  private

    attr_reader :score, :verdicts

    def llm_prompts
      Prompts.config
             .faithfulness
             .fetch(:reason)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        score:,
        contradictions:,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end

    def contradictions
      verdicts.select { |verdict| verdict["verdict"].strip.downcase == "no" }
              .map { |verdict| verdict["reason"] }
    end
  end
end
