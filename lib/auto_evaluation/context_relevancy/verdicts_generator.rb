module AutoEvaluation
  class ContextRelevancy::VerdictsGenerator
    def self.call(...) = new(...).call

    def initialize(truths:, information_needs:)
      @truths = truths
      @information_needs = information_needs
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("verdicts"), result.llm_response, result.metrics]
    end

  private

    attr_reader :truths, :information_needs

    def llm_prompts
      Prompts.config.context_relevancy.fetch(:verdicts)
    end

    def formatted_truths
      truths.map do |truth|
        <<~TRUTH
          Context: #{truth['context']}
          Facts:
          #{truth['facts'].join("\n")}
        TRUTH
      end
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        truths: formatted_truths,
        information_needs: information_needs.join("\n"),
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end
  end
end
