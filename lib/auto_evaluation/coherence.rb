module AutoEvaluation
  class Coherence
    THRESHOLD = 0.75

    def self.call(...) = new(...).call

    def initialize(question_message:, answer_message:)
      @question_message = question_message
      @answer_message = answer_message
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      score = normalise_rubric_score(result.evaluation_data.fetch("score"))

      AutoEvaluation::ScoreResult.new(
        score:,
        reason: result.evaluation_data.fetch("reason").strip,
        success: score >= THRESHOLD,
        llm_responses: { coherence: result.llm_response },
        metrics: { coherence: result.metrics },
      )
    end

  private

    attr_reader :question_message, :answer_message

    def llm_prompts
      Prompts.config.coherence
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        answer: answer_message,
        question: question_message,
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end

    def normalise_rubric_score(rubric_score)
      min_rubric_score = llm_prompts.fetch(:config).fetch(:min_rubric_score)
      max_rubric_score = llm_prompts.fetch(:config).fetch(:max_rubric_score)

      (rubric_score.to_d - min_rubric_score) / (max_rubric_score - min_rubric_score)
    end
  end
end
