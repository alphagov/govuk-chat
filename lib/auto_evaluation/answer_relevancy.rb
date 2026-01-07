class AutoEvaluation::AnswerRelevancy
  THRESHOLD = 0.5

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
    @llm_responses = {}
    @metrics = {}
  end

  def call
    statements, llm_responses[:statements], metrics[:statements] = StatementGenerator.call(answer_message: answer.message)

    if statements.empty?
      return build_maximum_score_result(
        reason: "No statements were extracted from the answer.",
        llm_responses:,
        metrics:,
      )
    end

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      question_message:, statements: statements,
    )

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

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      question_message:, verdicts:, score:,
    )

    AutoEvaluation::ScoreResult.new(
      score:,
      reason:,
      success: score >= THRESHOLD,
      llm_responses:,
      metrics:,
    )
  end

private

  attr_reader :answer
  attr_accessor :llm_responses, :metrics

  def question_message
    answer.question_used
  end

  def calculate_score(verdicts)
    verdict_count = verdicts.count
    return 1.0 if verdict_count.zero?

    relevant_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
    relevant_count.to_d / verdict_count
  end

  def build_maximum_score_result(reason:, llm_responses:, metrics:)
    AutoEvaluation::ScoreResult.new(
      score: 1.0,
      reason:,
      success: true,
      llm_responses:,
      metrics:,
    )
  end
end
