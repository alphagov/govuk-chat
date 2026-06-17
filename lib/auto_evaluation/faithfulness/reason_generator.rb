module AutoEvaluation
  class Faithfulness::ReasonGenerator
    def self.call(...) = new(...).call

    def initialize(score:, verdicts:)
      @score = score
      @verdicts = verdicts
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_message:, tool:)
      [result.evaluation_data.fetch("reason"), result.llm_response, result.metrics]
    end

  private

    attr_reader :score, :verdicts

    def llm_prompts
      Prompts.config
             .faithfulness
             .fetch(:reason)
    end

    def user_message
      sprintf(
        llm_prompts.fetch(:new_user_prompt),
        score:,
        unfaithful_claims:,
      )
    end

    def tool
      llm_prompts.fetch(:new_tool_spec)
    end

    def unfaithful_claims
      verdicts.filter_map do |verdict|
        status = verdict["verdict"].strip.downcase
        next if status == "yes"

        status == "idk" ? "(Ambiguous) #{verdict['reason']}" : "(Contradiction) #{verdict['reason']}"
      end
    end
  end
end
