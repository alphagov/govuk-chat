module AutoEvaluation
  class AnswerRelevancy
    Result = Data.define(
      :score,
      :reason,
      :success,
      :llm_responses,
      :metrics,
    )

    def self.call(...) = new(...).call

    def initialize(question_message:, answer_message:, threshold: 0.5)
      @question_message = question_message
      @answer_message = answer_message
      @threshold = threshold
    end

    def call
      statements, statements_llm_response, statements_metrics = StatementGenerator.call(answer_message:)

      llm_responses = { statements: statements_llm_response }
      metrics = { statements: statements_metrics }

      if statements.empty?
        return build_maximum_score_result(
          reason: "No statements were extracted from the answer.",
          llm_responses:,
          metrics:,
        )
      end

      verdicts, verdicts_llm_response, verdicts_metrics = VerdictsGenerator.call(
        question_message:, statements: statements,
      )

      llm_responses[:verdicts] = verdicts_llm_response
      metrics[:verdicts] = verdicts_metrics

      if verdicts.empty?
        return build_maximum_score_result(
          reason: "No verdicts were generated for the extracted statements.",
          llm_responses:,
          metrics:,
        )
      end

      if verdicts.none? { |verdict| verdict["verdict"].strip.downcase == "no" }
        return build_maximum_score_result(
          reason: "The response fully addressed the input with no irrelevant statements.",
          llm_responses:,
          metrics:,
        )
      end

      score = calculate_score(verdicts)
      reason, reason_llm_response, reason_metrics = ReasonGenerator.call(
        question_message:, verdicts:, score:,
      )

      llm_responses[:reason] = reason_llm_response
      metrics[:reason] = reason_metrics

      Result.new(
        score:,
        reason:,
        success: score >= threshold,
        llm_responses:,
        metrics:,
      )
    end

  private

    attr_reader :question_message, :answer_message, :threshold

    def calculate_score(verdicts)
      verdict_count = verdicts.count
      return 1.0 if verdict_count.zero?

      relevant_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase == "yes" }
      relevant_count.to_f / verdict_count
    end

    def build_maximum_score_result(reason:, llm_responses:, metrics:)
      Result.new(
        score: 1.0,
        reason:,
        success: true,
        llm_responses:,
        metrics:,
      )
    end
  end
end
