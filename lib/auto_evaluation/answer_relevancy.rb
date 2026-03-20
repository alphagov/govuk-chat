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

    return build_error_result("No statements were extracted from the answer.") if statements.empty?

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      question_message:, statements: statements,
    )

    return build_error_result("No verdicts were generated for the extracted statements.") if verdicts.empty?

    if verdicts.none? { |verdict| verdict["verdict"].strip.downcase == "no" }
      return build_result_with_score(
        1.0,
        "The response fully addressed the input with no irrelevant statements.",
      )
    end

    score = calculate_score(verdicts)

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      question_message:, verdicts:, score:,
    )

    build_result_with_score(score, reason)
  rescue AutoEvaluation::BedrockOpenAIOssInvoke::InvalidToolCallError => e
    build_error_result(e.message)
  end

private

  attr_reader :answer
  attr_accessor :llm_responses, :metrics

  def question_message
    answer.question_used
  end

  def calculate_score(verdicts)
    verdict_count = verdicts.count
    relevant_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
    relevant_count.to_d / verdict_count
  end

  def build_error_result(error_message)
    AutoEvaluation::Result.new(
      status: "error",
      error_message:,
      llm_responses:,
      metrics:,
    )
  end

  def build_result_with_score(score, reason)
    AutoEvaluation::Result.new(
      status: score >= THRESHOLD ? "success" : "failure",
      score:,
      reason:,
      llm_responses:,
      metrics:,
    )
  end
end
